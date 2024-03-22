CREATE TABLE people (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    birth_year INTEGER NOT NULL,
    death_year INTEGER
);

CREATE TABLE studios (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE movies (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    year TEXT NOT NULL,
    studio INTEGER REFERENCES studios(id)
);

CREATE TABLE jobs (
    name TEXT PRIMARY KEY
);

CREATE TABLE roles (
    person INTEGER REFERENCES people(id),
    job TEXT REFERENCES jobs(name),
    movie INTEGER REFERENCES movies(id),
    PRIMARY KEY (person, job, movie)
);
