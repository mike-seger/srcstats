# srcstats

This is a simple bash script, which can create a report with line and file
count statistics for source code repositories.

A report can be created as follows:

```
../srcstats/srcstats.sh 2 . 2>/tmp/debug.txt
```                                              

this produces:

path	| files	| lines
---	| ---	| ---
./dropwizard-2.0.22/.*/src/main/java	| 307	| 15438
./dropwizard-2.0.22/.*/src/test/java	| 310	| 18045
./maven-maven-3.8.1/.*/src/main/java	| 424	| 32554
./maven-maven-3.8.1/.*/src/test/java	| 162	| 10630
./metrics-4.1.22/.*/src/main/java	| 144	| 10575
./metrics-4.1.22/.*/src/test/java	| 102	| 7904
./micronaut-core-2.5.5-master/.*/src/main/java	| 1139	| 69887
./micronaut-core-2.5.5-master/.*/src/main/kotlin	| 2	| 106
./micronaut-core-2.5.5-master/.*/src/test/java	| 316	| 9907
./micronaut-core-2.5.5-master/.*/src/test/kotlin	| 327	| 8442
./spring-boot-2.4.6/.*/src/main/java	| 2698	| 144829
./spring-boot-2.4.6/.*/src/main/kotlin	| 5	| 258
./spring-boot-2.4.6/.*/src/test/java	| 1684	| 122463
./spring-boot-2.4.6/.*/src/test/kotlin	| 4	| 457
./spring-data-jdbc-2.2.1/.*/src/main/java	| 188	| 12791
./spring-data-jdbc-2.2.1/.*/src/main/kotlin	| 1	| 29
./spring-data-jdbc-2.2.1/.*/src/test/java	| 86	| 8678
./spring-data-jdbc-2.2.1/.*/src/test/kotlin	| 1	| 43
./spring-kafka-2.7.1/.*/src/main/java	| 196	| 15548
./spring-kafka-2.7.1/.*/src/main/kotlin	| 7	| 334
./spring-kafka-2.7.1/.*/src/test/java	| 55	| 8689
./spring-kafka-2.7.1/.*/src/test/kotlin	| 1	| 157
./testng-7.4.0/.*/src/main/java	| 154	| 7458
./testng-7.4.0/.*/src/test/java	| 858	| 21240


Some parameters to create the report can be customized in the file:  
 `srcstats.env` 
