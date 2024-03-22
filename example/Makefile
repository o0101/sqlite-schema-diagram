schema.svgz: schema.dot
	dot -Tsvgz -oschema.svgz schema.dot

schema.dot: database.sqlite3 ../sqlite-schema-diagram.sql
	sqlite3 -list database.sqlite3 < ../sqlite-schema-diagram.sql > schema.dot

database.sqlite3: schema.sql
	rm -f database.sqlite3
	sqlite3 database.sqlite3 < schema.sql
