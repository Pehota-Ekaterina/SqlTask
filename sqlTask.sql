CREATE DATABASE Banking;

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

SELECT City.CityName, Bank.BankName
FROM City
INNER JOIN BankCity ON City.Id = BankCity.IdCity
INNER JOIN Bank ON Bank.Id = BankCity.IdBank
WHERE City.CityName = 'Минск';

SELECT Account.Id, BalanceAccount, BankName, BalanceCard, FirstName, LastName
FROM Account 
INNER JOIN Card ON Card.IdAccount = Account.Id
INNER JOIN Client ON Client.Id = Account.IdClient
INNER JOIN Bank ON Bank.Id = Account.IdBank

SELECT IdAccount, SUM(BalanceAccount)/Count(*) AS BalanceAccount,  SUM(Card.BalanceCard) AS SumBalanceCard, (SUM(BalanceAccount)/Count(*) - SUM(Card.BalanceCard)) AS div
FROM Account INNER JOIN Card ON Account.Id = Card.IdAccount
GROUP BY IdAccount
HAVING SUM(BalanceAccount)/Count(*) <> SUM(BalanceCard)

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

