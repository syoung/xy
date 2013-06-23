CREATE TABLE IF NOT EXISTS linearSlider
(
    username        VARCHAR(30) NOT NULL,
    experiment      VARCHAR(30) NOT NULL,
    type            ENUM ('linear', 'log') ,
    xmin	        INT NOT NULL DEFAULT 0,
    xmax	        INT NOT NULL DEFAULT 1000 ,
    ymin	        INT NOT NULL DEFAULT 1,
    ymax	        INT NOT NULL DEFAULT 10,
    xvar_name	    'Cost',
    yvar_name	    'Value',

    PRIMARY KEY (username, experiment, type)
);
