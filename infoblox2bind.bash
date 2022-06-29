#!/bin/bash
# grep -P '^arecord' 220627_All\ DNS\ Objects.csv |cut -f2,4 -d, --output-delimiter=' '|sed 's/\.jhdc\.local//' |awk '{print "export IP="$1" ; export HOST="$2" ; echo -e $HOST\tIN\tA\t$IP "}' |bash |tr ' ' '\t'|tail -n5}'
: ${ZONE:=example.com}
: ${SERIAL:=202206281738}
: ${REFRESH:=604800}
: ${RETRY:=86400}
: ${TTL:=604800}
: ${VERBOSE:=0}
: ${EXPIRE:=2419200}
: ${NEGATIVE_CACHE_TTL:=604800}
: ${THIS_SERVER_IP:=10.0.0.1}

if [ $# -gt 1 ]; then
  # Print usage
  echo -n 'Error! wrong number of arguments'
  echo " [$#]"
  echo 'usage:'
  echo "$0 INPUT_CSV_FILE"
  exit 1
elif [ $# -eq 0 ]; then
  # We can use INPUT_CSV_FILE from a default or environment
: ${INPUT_CSV_FILE:=input.csv}
elif [ $# -eq 1 ]; then
  # Or we can take an input file as argument
INPUT_CSV_FILE=$1
fi

if [[ -f $INPUT_CSV_FILE ]]; then
  if [[ $VERBOSE -gt 0 ]]; then
    echo "using $INPUT_CSV_FILE"
  fi
else
  echo 'Please supply an INPUT_CSV_FILE'
  echo 'e.g.'
  echo "$0 /tmp/555_All\ DNS\ Objects.csv"
  exit 1
fi

TMP=$(mktemp -d)

cat <<EOF > $TMP/zone.$ZONE.db
; BIND data file for us-ne-1 lan0
;
\$TTL   $TTL
@       IN      SOA     $ZONE. (
                     admin.$ZONE. ; Owner
                   $SERIAL         ; Serial - increment after save
                         $REFRESH         ; Refresh
                          $RETRY         ; Retry
                        $EXPIRE         ; Expire
                         $NEGATIVE_CACHE_TTL )       ; Negative Cache TTL
;

@           IN      NS    $ZONE.
@           IN      A     $THIS_SERVER_IP ; Address of this server
EOF

echo_slurp () {
  if [[ $VERBOSE -gt 10 ]]; then
    echo $slurped|tr ' ' '\n'|less
  fi
}

find_records_by_type () {
  TYPE=$1
  slurped=$( grep -P  "^$TYPE" "$INPUT_CSV_FILE" | cut -d "," -f2,4 | sed "s/\.$ZONE//" )
  echo_slurp
  while IFS="," read -r IP HOST 
  do
    printf '%s\tIN\tA\t%s\n' $HOST $IP >> $TMP/$TYPE.zone.$ZONE.db
  done <<< $slurped
}

find_records_by_type_host_first () {
  TYPE=$1
  slurped=$( grep -P  "^$TYPE" "$INPUT_CSV_FILE" | cut -d "," -f2,4 | sed "s/\.$ZONE//" )
  echo_slurp
  while IFS="," read -r HOST IP  
  do
    printf '%s\tIN\tA\t%s\n' $HOST $IP >> $TMP/$TYPE.zone.$ZONE.db
  done <<< $slurped
  #done < <( grep -P  "$TYPE" "$INPUT_CSV_FILE" | cut -d "," -f2,4 | sed "s/\.$ZONE//" ) >> $TMP/zone.$ZONE.db
}

find_records_by_type 'arecord'

# not certain what the difference is here
find_records_by_type 'hostaddress'
# I think this is redundant or may be used to make PTR records, but am including as it does add some unique hosts
find_records_by_type_host_first 'hostrecord'

cat $TMP/arecord.zone.$ZONE.db  $TMP/hostaddress.zone.$ZONE.db  $TMP/hostrecord.zone.$ZONE.db |sort|uniq >> $TMP/zone.$ZONE.db
#cat $TMP/arecord.zone.$ZONE.db  |sort|uniq >> $TMP/zone.$ZONE.db

if [[ $VERBOSE -gt 0 ]]; then
  #head -n25 $TMP/zone.$ZONE.db
  #less $TMP/zone.$ZONE.db
  sort $TMP/zone.$ZONE.db |uniq -c|sort -rn|less
  wc -l $TMP/zone.$ZONE.db
  #ls -alh $TMP|less
  #cat $TMP/arecord.zone.$ZONE.db  $TMP/hostaddress.zone.$ZONE.db  $TMP/hostrecord.zone.$ZONE.db |sort|uniq -c|sort -rn|less
fi
echo -e "Your zone file is here --> $TMP/zone.$ZONE.db"
