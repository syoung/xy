CREATE TABLE IF NOT EXISTS experiment
(
    username        VARCHAR(30) NOT NULL,
    experiment      VARCHAR(30) NOT NULL,
    datetime        DATETIME NOT NULL,
    name        	VARCHAR(30) NOT NULL,
    value			INT(10) NOT NULL,

    PRIMARY KEY (username, experiment, type, datetime)
);