# srcstats

This is a simple bash script, which can create a report with line and file
count statistics for source code repositories.

```
$ ./srcstats.sh                             
Usage: ./srcstats.sh [-ef <env-file> | -e <env-file-type>] <max_depth> <root_dir1> [<root_dir2> ...]
```

A report can be created as follows:

```
./srcstats.sh 1 *kafka*
```                                              

this produces somethin like:

path	| files	| lines
---	| ---	| ---
...	| 7	| 474
spring-kafka-2.7.1...adoc	| 18	| 5053
spring-kafka-2.7.1...bat	| 1	| 68
spring-kafka-2.7.1...conf	| 1	| 6
spring-kafka-2.7.1...css	| 1	| 21
spring-kafka-2.7.1...factories	| 1	| 3
spring-kafka-2.7.1...gradle	| 6	| 515
spring-kafka-2.7.1...html	| 2	| 21
spring-kafka-2.7.1...java	| 442	| 52138
spring-kafka-2.7.1...json	| 1	| 11
spring-kafka-2.7.1...kt	| 8	| 491
spring-kafka-2.7.1...md	| 2	| 72
spring-kafka-2.7.1...properties	| 4	| 14
spring-kafka-2.7.1...txt	| 3	| 188
spring-kafka-2.7.1...xml	| 9	| 438
spring-kafka-2.7.1...yml	| 7	| 138

Some parameters to collect the files for the report can be customized here:  
 `srcstats.env` 
