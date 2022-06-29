#!/bin/bash
# grep -P '^arecord' 220627_All\ DNS\ Objects.csv |cut -f2,4 -d, --output-delimiter=' '|sed 's/\.jhdc\.local//' |awk '{print "export IP="$1" ; export HOST="$2" ; echo -e $HOST\tIN\tA\t$IP "}' |bash |tr ' ' '\t'|tail -n5}'
THIS_PWD=$(pwd)
: ${ZONE:=example.com}
: ${SERIAL:=$(date +%Y%m%d%H)}
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

cat <<EOF > $TMP/zone.$ZONE
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

cat <<EOF > $TMP/named.conf
options {
  directory "/var/cache/bind";
  //dnssec-validation auto;
  dnssec-validation no;
  listen-on-v6 { any; };
};
include "/etc/bind/named.conf.$ZONE";
EOF

cat <<EOF > $TMP/named.conf.$ZONE
zone "$ZONE" {
    type master;
    file "/etc/bind/zone.$ZONE";
};
EOF

cat <<EOF > $TMP/run
#!/bin/sh
set -eux
docker run -it -d --rm \
  --cidfile=.cid \
  -v $THIS_PWD/named.conf:/etc/bind/named.conf \
  -v $THIS_PWD/named.conf.$ZONE:/etc/bind/named.conf.$ZONE \
  -v $THIS_PWD/zone.$ZONE:/etc/bind/zone.$ZONE \
  --name bind9-container \
  -e TZ=UTC \
  -p 53:53 \
  -p 53:53/udp \
  ubuntu/bind9:latest
EOF
chmod +x $TMP/run

echo_slurp () {
  if [[ $VERBOSE -gt 10 ]]; then
    echo $slurped|tr ' ' '\n'|less
  fi
}

find_records_by_type () {
  FIRST_FIELD=$1
  SECOND_FIELD=$2
  TYPE=$3
  slurped=$( grep -P  "^$TYPE" "$INPUT_CSV_FILE" | cut -d "," -f2,4 | sed "s/\.$ZONE//" | sed 's/"//g' )
  echo_slurp
  while IFS="," read -r $FIRST_FIELD $SECOND_FIELD
  do
    printf '%s\tIN\tA\t%s\n' $HOST $IP >> $TMP/$TYPE.zone.$ZONE
  done <<< $slurped
}

find_records_by_type IP HOST 'arecord'

# not certain what the difference is here
find_records_by_type IP HOST 'hostaddress'
# I think this is redundant or may be used to make PTR records, but am including as it does add some unique hosts
find_records_by_type HOST IP 'hostrecord'

cat $TMP/arecord.zone.$ZONE  $TMP/hostaddress.zone.$ZONE  $TMP/hostrecord.zone.$ZONE |sort|uniq >> $TMP/zone.$ZONE
#cat $TMP/arecord.zone.$ZONE  |sort|uniq >> $TMP/zone.$ZONE

if [[ $VERBOSE -gt 0 ]]; then
  #head -n25 $TMP/zone.$ZONE
  #less $TMP/zone.$ZONE
  sort $TMP/zone.$ZONE |uniq -c|sort -rn|less
  wc -l $TMP/zone.$ZONE
  #ls -alh $TMP|less
  #cat $TMP/arecord.zone.$ZONE  $TMP/hostaddress.zone.$ZONE  $TMP/hostrecord.zone.$ZONE |sort|uniq -c|sort -rn|less
fi
#echo -e "Your zone file is here --> $TMP/zone.$ZONE"
mv -v $TMP/zone.$ZONE $THIS_PWD/
mv -v $TMP/named.conf $THIS_PWD/
mv -v $TMP/named.conf.$ZONE $THIS_PWD/
mv -v $TMP/run $THIS_PWD/
rm $TMP/arecord.zone.example.com
rm $TMP/hostaddress.zone.example.com
rm $TMP/hostrecord.zone.example.com
rmdir $TMP
exit 0
