CREATE TABLE IF NOT EXISTS report
(
    username        VARCHAR(30) NOT NULL,
    project         VARCHAR(20) NOT NULL,
    workflow        VARCHAR(20) NOT NULL,
    appname         VARCHAR(40),
    appnumber       VARCHAR(10),

    name            VARCHAR(20),
    notes           TEXT,
    datetime        DATETIME NOT NULL,
    
    PRIMARY KEY (username, project, workflow, appname, appnumber, name)
);