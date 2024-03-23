schema.svg: schema.dot
	dot -Tsvg -oschema.svg schema.dot

schema.dot: database.sqlite3 ../sqlite-schema-diagram.sql
	sqlite3 database.sqlite3 -init ../sqlite-schema-diagram.sql "" > schema.dot

database.sqlite3: schema.sql
	rm -f database.sqlite3
	sqlite3 database.sqlite3 < schema.sql
