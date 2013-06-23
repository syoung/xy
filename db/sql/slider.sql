CREATE TABLE IF NOT EXISTS slider
(
    username        VARCHAR(30) NOT NULL,
    experiment      VARCHAR(30) NOT NULL,
    
    graph           ENUM ('linear', 'log') ,
    min	            INT NOT NULL DEFAULT 0,
    max	            INT NOT NULL DEFAULT 1000 ,

    type            VARCHAR(30) NOT NULL,
    label           VARCHAR(30),

    PRIMARY KEY (username, experiment, type)
);
