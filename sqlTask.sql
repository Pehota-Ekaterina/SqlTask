--0
CREATE DATABASE Banking;
GO

CREATE TABLE City
(
	Id INT PRIMARY KEY IDENTITY,
	CityName NVARCHAR(50) NOT NULL UNIQUE 
);

CREATE TABLE Bank
(
	Id INT PRIMARY KEY IDENTITY,
	BankName NVARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE BankCity
(
	IdBank INT NOT NULL CHECK(IDbANK > 0) REFERENCES Bank (Id),
	IdCity INT NOT NULL CHECK(IDCity > 0) REFERENCES City (Id)
);

CREATE TABLE SocialStatus
(
	Id INT PRIMARY KEY IDENTITY,
	StatusName NVARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE Client
(
	Id INT PRIMARY KEY IDENTITY,
	FirstName NVARCHAR(50) NOT NULL,
	LastName NVARCHAR(50) NOT NULL,
	DateOdBirth DATE NOT NULL,
	IdSocialStatus INT NOT NULL CHECK(IdSocialStatus > 0) REFERENCES SocialStatus (Id)
	CONSTRAINT UC_Client UNIQUE (FirstName, LastName, DateOdBirth)
);

CREATE TABLE Account
(
	Id INT PRIMARY KEY IDENTITY,
	BalanceAccount DECIMAL NOT NULL CHECK(BalanceAccount >= 0),
	IdBank INT NOT NULL CHECK(IdBank > 0) REFERENCES Bank (Id),
	IdClient INT NOT NULL CHECK(IdClient > 0) REFERENCES Client (Id) 
);

CREATE TABLE Card
(
	Id INT PRIMARY KEY IDENTITY,
	BalanceCard DECIMAL NOT NULL CHECK(BalanceCard >= 0),
	IdAccount INT NOT NULL CHECK(IdAccount > 0) REFERENCES Account (Id)
);

--1
SELECT City.CityName, Bank.BankName
FROM City
INNER JOIN BankCity ON City.Id = BankCity.IdCity
INNER JOIN Bank ON Bank.Id = BankCity.IdBank
WHERE City.CityName = 'Минск';

--2
SELECT Account.Id, BalanceAccount, BankName, BalanceCard, FirstName, LastName
FROM Account 
INNER JOIN Card ON Card.IdAccount = Account.Id
INNER JOIN Client ON Client.Id = Account.IdClient
INNER JOIN Bank ON Bank.Id = Account.IdBank

--3
SELECT IdAccount, SUM(DISTINCT BalanceAccount) AS BalanceAccount,  SUM(Card.BalanceCard) AS SumBalanceCard, (SUM(DISTINCT BalanceAccount) - SUM(Card.BalanceCard)) AS div
FROM Account INNER JOIN Card ON Account.Id = Card.IdAccount
GROUP BY IdAccount
HAVING SUM(DISTINCT BalanceAccount) <> SUM(BalanceCard)

--4
SELECT IdSocialStatus, StatusName, ClientCountCard
FROM SocialStatus INNER JOIN
	(SELECT IdSocialStatus, SUM(CountCard) AS ClientCountCard
	FROM Client INNER JOIN
	(SELECT Account.IdClient, AccountCards.CountCard 
		FROM Account INNER JOIN
		(SELECT Account.Id, Count(*) AS CountCard
			FROM Account INNER JOIN Card 
			ON Card.IdAccount = Account.Id
			GROUP BY Account.Id ) AS AccountCards 
		ON Account.Id = AccountCards.Id) AS AccountCountCards 
	ON AccountCountCards.IdClient = Client.Id
	GROUP BY IdSocialStatus) AS ClientCountCard
ON SocialStatus.Id = ClientCountCard.IdSocialStatus;

--5
USE Banking;
GO

CREATE PROCEDURE ChangeBalanceAccount
	@idSocialStatus INT
AS
BEGIN
	IF NOT EXISTS ( SELECT 1 FROM SocialStatus WHERE SocialStatus.Id = @idSocialStatus )
		BEGIN
			PRINT 'social status with this id does not exist in the database'
		END

	ELSE IF NOT EXISTS(SELECT 1 FROM Client WHERE Client.IdSocialStatus = @idSocialStatus)
		BEGIN
			PRINT 'client with this social status does not exist in the database' 
		END

	ELSE
		BEGIN
			UPDATE ClientAccount
			SET ClientAccount.BalanceAccount = ClientAccount.BalanceAccount + 10 
			FROM
				(SELECT Client.IdSocialStatus, BalanceAccount
				FROM Client INNER JOIN Account
				ON Client.Id = Account.IdClient) AS ClientAccount
			WHERE ClientAccount.IdSocialStatus = @idSocialStatus
		END
END;
GO

SELECT StatusName, IdClient, FirstName, LastName, IdAccount, BalanceAccount
FROM SocialStatus INNER JOIN
	(SELECT Client.Id AS IdClient, FirstName, LastName, Account.Id AS IdAccount, BalanceAccount, IdSocialStatus
	FROM Client INNER JOIN Account
	ON Client.Id = Account.IdClient) AS ClientAccount
ON SocialStatus.Id = ClientAccount.IdSocialStatus;

EXEC ChangeBalanceAccount 5

SELECT StatusName, IdClient, FirstName, LastName, IdAccount, BalanceAccount
FROM SocialStatus INNER JOIN
	(SELECT Client.Id AS IdClient, FirstName, LastName, Account.Id AS IdAccount, BalanceAccount, IdSocialStatus
	FROM Client INNER JOIN Account
	ON Client.Id = Account.IdClient) AS ClientAccount
ON SocialStatus.Id = ClientAccount.IdSocialStatus;

--6
SELECT Client.Id, FirstName, LastName, SumBalanceCardClient
FROM Client INNER JOIN
	(SELECT Client.Id AS Id, SUM(SumBalanceCard) AS SumBalanceCardClient
	FROM Client INNER JOIN
		(SELECT Account.IdClient, SumBalanceCard
		FROM Account INNER JOIN
			(SELECT IdClient, SUM(Card.BalanceCard) AS SumBalanceCard
			FROM Account INNER JOIN Card ON Account.Id = Card.IdAccount
			GROUP BY IdClient) AS AccountCard
		ON Account.IdClient = AccountCard.IdClient) AS AccountCards
	ON Client.Id = AccountCards.IdClient
	GROUP BY Client.Id) AS ClientCards
ON ClientCards.Id = Client.Id

--7
USE Banking;
GO

CREATE PROCEDURE MoneyTransfer
	@idAccount INT,
	@transferAmount DECIMAL
AS
BEGIN
	BEGIN TRY
	BEGIN TRANSACTION

	IF NOT EXISTS ( SELECT 1 FROM Account WHERE Account.Id = @idAccount )
		BEGIN
			PRINT 'this account does not exist'
			ROLLBACK TRANSACTION
			RETURN
		END

	ELSE IF NOT EXISTS ( SELECT 1 FROM Card WHERE Card.IdAccount = @idAccount )
		BEGIN
			PRINT 'this account has no cards'
			ROLLBACK TRANSACTION
			RETURN
		END

	ELSE IF EXISTS (SELECT IdAccount, SUM(DISTINCT BalanceAccount) AS BalanceAccount,  SUM(Card.BalanceCard) AS SumBalanceCard
				FROM Account INNER JOIN Card ON Account.Id = Card.IdAccount
				GROUP BY IdAccount
				HAVING (SUM(DISTINCT BalanceAccount) - SUM(BalanceCard)) < @transferAmount)
		BEGIN
			PRINT 'not enough money to transfer'
			ROLLBACK TRANSACTION
			RETURN
		END

	ELSE
		BEGIN
			UPDATE AccountCard
			SET BalanceCard = BalanceCard + @transferAmount
			FROM
				(SELECT IdAccount, Card.Id AS IdCard, BalanceCard
				FROM Card INNER JOIN Account
				ON Card.IdAccount = Account.Id) AS AccountCard
			WHERE IdAccount = @idAccount
		END

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SELECT ERROR_NUMBER() AS [Номер ошибки],
             ERROR_MESSAGE() AS [Описание ошибки]
	RETURN
	END CATCH
	COMMIT TRANSACTION
END;
GO

SELECT IdAccount, BalanceAccount, Card.Id AS IdCard, BalanceCard
FROM Card INNER JOIN Account
ON Card.IdAccount = Account.Id
WHERE IdAccount = 2;

EXEC MoneyTransfer 2, 1000

SELECT IdAccount, BalanceAccount, Card.Id AS IdCard, BalanceCard
FROM Card INNER JOIN Account
ON Card.IdAccount = Account.Id
WHERE IdAccount = 2;
