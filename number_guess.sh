#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

INPUT_NAME() {
  echo "Enter your username:"
  read NAME
  NAME_LENGTH=${#NAME}

  # Check username length and validity
  if [[ $NAME_LENGTH -le 22 && $NAME_LENGTH -gt 0 ]]
  then
    USER_NAME=$(echo $($PSQL "SELECT username FROM users WHERE username='$NAME';") | sed 's/ //g')
    if [[ ! -z $USER_NAME ]]
    then
      # Retrieve user info if the username exists
      USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USER_NAME';")
      GAMES_PLAYED=$($PSQL "SELECT frequent_games FROM users WHERE user_id=$USER_ID;")
      BEST_GAME=$($PSQL "SELECT MIN(best_guess) FROM games WHERE user_id=$USER_ID;")
      echo "Welcome back, $USER_NAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
    else
      # New user
      echo "Welcome, $NAME! It looks like this is your first time here."
      INSERT_NEW_USER=$($PSQL "INSERT INTO users(username, frequent_games) VALUES('$NAME', 0);")
      USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$NAME';")
    fi
    START_GAME $USER_ID
  else
    INPUT_NAME
  fi
}

START_GAME() {
  USER_ID=$1
  SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
  echo "Guess the secret number between 1 and 1000:"
  GUESS_COUNT=0
  INPUT_GUESS $SECRET_NUMBER $GUESS_COUNT $USER_ID
}

INPUT_GUESS() {
  SECRET_NUMBER=$1
  GUESS_COUNT=$2
  USER_ID=$3

  read GUESS

  # Validate input
  if ! [[ $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    INPUT_GUESS $SECRET_NUMBER $GUESS_COUNT $USER_ID
  else
    GUESS_COUNT=$((GUESS_COUNT + 1))
    CHECK_ANSWER $GUESS $SECRET_NUMBER $GUESS_COUNT $USER_ID
  fi
}

CHECK_ANSWER() {
  GUESS=$1
  SECRET_NUMBER=$2
  GUESS_COUNT=$3
  USER_ID=$4

  if [[ $GUESS -lt $SECRET_NUMBER ]]
  then
    echo "It's higher than that, guess again:"
    INPUT_GUESS $SECRET_NUMBER $GUESS_COUNT $USER_ID
  elif [[ $GUESS -gt $SECRET_NUMBER ]]
  then
    echo "It's lower than that, guess again:"
    INPUT_GUESS $SECRET_NUMBER $GUESS_COUNT $USER_ID
  else
    echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"
    SAVE_GAME $USER_ID $GUESS_COUNT
  fi
}

SAVE_GAME() {
  USER_ID=$1
  GUESS_COUNT=$2

  # Update the user's game record
  UPDATE_GAME_COUNT=$($PSQL "UPDATE users SET frequent_games = frequent_games + 1 WHERE user_id = $USER_ID;")
  INSERT_GAME=$($PSQL "INSERT INTO games(user_id, best_guess) VALUES($USER_ID, $GUESS_COUNT);")
}

INPUT_NAME
