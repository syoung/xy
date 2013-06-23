CREATE TABLE IF NOT EXISTS dataseries
(
    username        VARCHAR(30) NOT NULL,
    experiment      VARCHAR(30) NOT NULL,
    datetime        DATETIME NOT NULL,
    x               INT(10) NOT NULL,
    y               INT(10) NOT NULL,

    PRIMARY KEY (username, experiment, x, y)
);
