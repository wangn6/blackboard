# this is to learn the shell programing
# the test functionalities
val1='Hello World'
echo $val1
echo "$val1"
if [ -n "$val1" ]
then
  echo "$val1 is not empty"
fi

if test '$val1'=''
then
 echo "'$val1' is not empty"
fi

# iterate the folder items
for file in /Users/neilwang/*; do
  if [ -d $file ]; then
    echo "$file is a directory!"
  elif [ -f $file ]; then
    echo "$file is a file!"
  fi
done
