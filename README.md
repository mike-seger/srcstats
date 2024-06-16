# srcstats

This is a simple bash script, which can create a report with line and file
count statistics for source code repositories.

```
$ ./srcstats.sh                             
./srcstats.sh <min consolidation path depth> <root path 1> ... [<root path n>]
```

A report can be created as follows:

```
./srcstats.sh 1 *kafka*
```                                              

this produces somethin like:

path	| files	| lines
---	| ---	| ---
./spring-kafka-2.7.1/.*/src/main/java	| 196	| 15548
./spring-kafka-2.7.1/.*/src/main/kotlin	| 7	| 334
./spring-kafka-2.7.1/.*/src/test/java	| 55	| 8689
./spring-kafka-2.7.1/.*/src/test/kotlin	| 1	| 157


Some parameters to collect the files for the report can be customized here:  
 `srcstats.env` 
