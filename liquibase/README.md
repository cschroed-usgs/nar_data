To insert the serialized data into a database, run something like:
```
mvn -Pupdate prepare-package -Ddb.username=<username> -Ddb.url=<jdbc url> -Ddb.password=<password -Dnar.data.location=<serialized data directory>
```

example:
```
mvn -Pupdate prepare-package -Ddb.username=postgres -Ddb.url=jdbc:postgresql://localhost:5432/postgres -Ddb.password=234.#@Fasfdoij90@# -Dnar.data.location=/home/cschroed/src/nar_data/inst/extdata
```

Alternatively, you can add the properties (anything specified via -D options) to your .m2/settings.xml file
