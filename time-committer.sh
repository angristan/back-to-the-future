#!/bin/bash

# BSD and GNU `date` aren't the same
# So we have to check this in order to use the correct options later
if [ "$(date)" == "$(date -d +0days 2>&1)" ]; then
  # Using date from coreutils, probably Linux
  GNU=true
else
  # Using a Mac or BSD
  BSD=true
fi

while [[ $time != "p" && $time != "f" ]]; do
  read -rp "Do you want to commit into the future or into the past? [f/p] " -e time
done

until [[ $end_day =~ ^[0-9]+$ ]]; do
  read -rp "How much days do you want to commit? (positive integer) " -e end_day
done

# Set options for the `for` loop
if [ "$time" == "p" ]; then
  end_day="-$end_day"
  incr="-1"
elif [ "$time" == "f" ]; then
  end_day="$end_day"
  incr="1"
fi

# BSD's date doesn't understand "date in 0 days"
# So we have to start at "date in 1 day" or "date 1 day ago"
if [ "$GNU" == true ]; then
  start_day='0'
elif [ "$BSD" == true ]; then
  if [ "$time" == 'p' ]; then
    start_day='-1'
  elif [ "$time" == 'f' ]; then
    start_day='1'
  fi
fi

for day_number in $(seq $start_day $incr $end_day); do
  # In a negative `for` loop, `day_number` will have a - sign
  # But in a positive loop, it won't have a +
  # However we need the - and + for the `date` command
  if [ "$time" == "f" ]; then
    day_number="+$day_number"
  fi

  echo $day_number

  # Set the correct arguments according to the installed `date`
  if [ "$GNU" == true ]; then
    date="date -d ${day_number}days"
  elif [ "$BSD" == true ]; then
    date="date -v ${day_number}d"
  fi
  
  # Write the date to a text file so we'll commit it
  eval "$date" > date.txt
  git add date.txt
  # First, commit the file as usual
  git commit -m "$(eval "$date")"
  # Then, change the commit date and ammend the commit
  GIT_COMMITTER_DATE="$(eval "$date")"
  git commit --amend --no-edit --date "$(eval "$date")"
done

