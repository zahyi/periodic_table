#!/bin/bash
PSQL="psql -X --username=freecodecamp --dbname=periodic_table --tuples-only -c"

FIX_DATABASE() {
  #You should rename the weight column to atomic_mass
  RENAME_WEIGHT=$($PSQL "ALTER TABLE properties RENAME COLUMN weight TO atomic_mass;")
	
	#You should rename the melting_point column to melting_point_celsius and the boiling_point column to boiling_point_celsius
	RENAME_MP=$($PSQL "ALTER TABLE properties RENAME COLUMN melting_point TO melting_point_celsius;")
	RENAME_BP=$($PSQL "ALTER TABLE properties RENAME COLUMN boiling_point TO boiling_point_celsius;")
	
	#Your melting_point_celsius and boiling_point_celsius columns should not accept null values
 	SET_MP_NN=$($PSQL "ALTER TABLE properties ALTER COLUMN melting_point_celsius SET NOT NULL;")
	SET_BP_NN=$($PSQL "ALTER TABLE properties ALTER COLUMN boiling_point_celsius SET NOT NULL;")
	
	#You should add the UNIQUE constraint to the symbol and name columns from the elements table
	SET_SYMBOL_UNIQUE=$($PSQL "ALTER TABLE elements ADD UNIQUE(symbol);")
	SET_NAME_UNIQUE=$($PSQL "ALTER TABLE elements ADD UNIQUE(name);")
	
	#Your symbol and name columns should have the NOT NULL constraint
	SET_SYMBOL_NN=$($PSQL "ALTER TABLE elements ALTER COLUMN symbol SET NOT NULL;")
	SET_NAME_NN=$($PSQL "ALTER TABLE elements ALTER COLUMN name SET NOT NULL;")
	
	#You should set the atomic_number column from the properties table as a foreign key that references the column of the same name in the elements table
	SET_FOREIGN_KEY=$($PSQL "ALTER TABLE properties ADD FOREIGN KEY(atomic_number) REFERENCES elements(atomic_number);")
	
	#You should create a types table that will store the three types of elements
	#Your types table should have a type_id column that is an integer and the primary key
	#Your types table should have a type column that's a VARCHAR and cannot be null. It will store the different types from the type column in the properties table
	CREATE_TYPES=$($PSQL "CREATE TABLE types(type_id SERIAL PRIMARY KEY, type VARCHAR(30) NOT NULL);")
	
	#You should add three rows to your types table whose values are the three different types from the properties table
	INSERT_ROWS=$($PSQL "INSERT INTO types(type) SELECT DISTINCT(type) FROM properties")
	
	#Your properties table should have a type_id foreign key column that references the type_id column from the types table. It should be an INT with the NOT NULL constraint
	SET_REFERENCES_TYPE_ID=$($PSQL "ALTER TABLE properties ADD COLUMN type_id INT REFERENCES types(type_id);")

	#Each row in your properties table should have a type_id value that links to the correct type from the types table
	SET_TYPE_IDS=$($PSQL "UPDATE properties SET type_id= (SELECT type_id FROM types WHERE properties.type = types.type);")
	SET_TYPE_ID_NN=$($PSQL "ALTER TABLE properties ALTER COLUMN type_id SET NOT NULL;")
	
	#You should capitalize the first letter of all the symbol values in the elements table. Be careful to only capitalize the letter and not change any others
	INITCAP_SYMBOL=$($PSQL "UPDATE elements SET symbol=INITCAP(symbol);")

	#You should remove all the trailing zeros after the decimals from each row of the atomic_mass column. You may need to adjust a data type to DECIMAL for this. The final values they should be are in the atomic_mass.txt file
	DEC_POINT=$($PSQL "ALTER TABLE properties ALTER COLUMN atomic_mass TYPE REAL;")
	
	#You should add the element with atomic number 9 to your database. Its name is Fluorine, symbol is F, mass is 18.998, melting point is -220, boiling point is -188.1, and it's a nonmetal
	#You should add the element with atomic number 10 to your database. Its name is Neon, symbol is Ne, mass is 20.18, melting point is -248.6, boiling point is -246.1, and it's a nonmetal
	INSERT_FLUORINE=$($PSQL "INSERT INTO elements(atomic_number, symbol, name) VALUES(9, 'F', 'Fluorine'), (10, 'Ne', 'Neon');")
	INSERT_NEON=$($PSQL "INSERT INTO properties(atomic_number, type, type_id, atomic_mass, melting_point_celsius, boiling_point_celsius) VALUES(9, 'nonmetal', 3, 18.998, -220, -188.1), (10, 'nonmetal', 3, 20.18, -248.6, -246.1);")
	#delete non-existent element from 1) properties then 2) elements
	DELETE_NON_EXIST_PROPERTIES=$($PSQL "DELETE FROM properties WHERE atomic_number=1000;")
	DELETE_NON_EXIST_ELEMENTS=$($PSQL "DELETE FROM elements WHERE atomic_number=1000;")

	#delete type column from properties
	DELETE_TYPE_COLUMN=$($PSQL "ALTER TABLE properties DROP COLUMN type;")
}

#script for output
RUN() {
  if [[ -z $1 ]]
  then
    echo "Please provide an element as an argument."
  else
    ELEMENT_INFO $1
  fi
}

ELEMENT_INFO() {
  INPUT=$1

  if [[ ! $INPUT =~ ^[0-9]+$ ]]
  then
  #if word, find atomic number
    ATOM=$($PSQL "SELECT atomic_number FROM elements WHERE symbol='$INPUT' OR name='$INPUT';")
  #else number,
  else
    ATOM=$($PSQL "SELECT atomic_number FROM elements WHERE atomic_number=$INPUT;")
  fi
  
  if [[ -z $ATOM ]]
  then
    echo "I could not find that element in the database."
  else
    ELEMENT=$($PSQL "SELECT * FROM elements FULL JOIN properties USING(atomic_number) LEFT JOIN types USING(type_id) WHERE atomic_number=$ATOM;")
    echo "$ELEMENT" | while read TYPE_ID BAR ATOMIC_NUMBER BAR SYMBOL BAR NAME BAR ATOMIC_MASS BAR MELTING_POINT_CELSIUS BAR BOILING_POINT_CELSIUS BAR TYPE
  do
    echo "The element with atomic number $ATOMIC_NUMBER is $NAME ($SYMBOL). It's a $TYPE, with a mass of $ATOMIC_MASS amu. $NAME has a melting point of $MELTING_POINT_CELSIUS celsius and a boiling point of $BOILING_POINT_CELSIUS celsius."
  done
  fi  
}

#start program
START() {
  CHECK=$($PSQL "SELECT COUNT(*) FROM elements WHERE atomic_number=1000;")
  if [[ $CHECK -gt 0 ]]
  then
    FIX_DATABASE
    clear
  fi
  RUN $1
}

START $1
