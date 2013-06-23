CREATE TABLE IF NOT EXISTS poll
(
    username        VARCHAR(30) NOT NULL,
    experiment      VARCHAR(30) NOT NULL,
    delay           INT(10) NOT NULL,       -- notification_succ

    PRIMARY KEY (username, experiment)
);
