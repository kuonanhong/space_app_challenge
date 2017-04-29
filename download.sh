#!/bin/bash

GREP_OPTIONS=''

cookiejar=$(mktemp cookies.XXXXXXXXXX)
netrc=$(mktemp netrc.XXXXXXXXXX)
chmod 0600 "$cookiejar" "$netrc"
function finish {
  rm -rf "$cookiejar" "$netrc"
  dot_netrc_tmp=$(mktemp ~/.netrc.tmp.XXXXXXXXXX)
  chmod 0600 "$dot_netrc_tmp"
  if [ -e ~/.netrc ]
  then
    awk '!/l5ftl01\.larc\.nasa\.gov/' ~/.netrc > $dot_netrc_tmp && mv $dot_netrc_tmp ~/.netrc
  fi
}

trap finish EXIT
WGETRC="$wgetrc"

prompt_credentials() {
    echo "Enter your Earthdata Login or other provider supplied credentials"
    read -p "Username (olala7846): " username
    username=${username:-olala7846}
    read -s -p "Password: " password
    echo "\nmachine urs.earthdata.nasa.gov\tlogin $username\tpassword $password" >> $netrc
    echo "\nmachine l5ftl01.larc.nasa.gov\tlogin $username\tpassword $password" >> $netrc
    echo
}

exit_with_error() {
    echo
    echo "Unable to Retrieve Data"
    echo
    echo $1
    echo
    echo "ftp://l5ftl01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2017.02.01/MISR_AM1_CGAS_FEB_2017_F15_0031.hdf"
    echo
    exit 1
}

prompt_credentials

  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 2 --netrc-file "$netrc" ftp://l5ftl01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2017.02.01/MISR_AM1_CGAS_FEB_2017_F15_0031.hdf -w %{http_code} | tail  -1`
    if [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w %{http_code} ftp://l5ftl01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2017.02.01/MISR_AM1_CGAS_FEB_2017_F15_0031.hdf | tail -1)
    if [[ "$status" -ne "200" && "$status" -ne "304" ]]; then
        # FTP retrieval. Set netrc file before curl-ing.
        echo "\nmachine l5ftl01.larc.nasa.gov\tlogin $username\tpassword $password" >> $netrc
    fi
}

setup_auth_wget() {
    # The safest way to auth via curl is netrc. Note: there's no checking or feedback
    # if login is unsuccessful
    touch ~/.netrc
    chmod 0600 ~/.netrc
    ftp_hostname='l5ftl01.larc.nasa.gov'
    credentials=$(grep $ftp_hostname ~/.netrc)
    if [ -z "$credentials" ]; then
        echo "\nmachine l5ftl01.larc.nasa.gov\tlogin $username\tpassword $password" >> ~/.netrc
    fi
    credentials=$(grep 'machine urs.earthdata.nasa.gov' ~/.netrc)
    if [ -z "$credentials" ]; then
        cat "$netrc" >> ~/.netrc
    fi
}

    fetch_urls() {
    if command -v curl >/dev/null 2>&1; then
        setup_auth_curl
        while read -r line; do
            curl -f -Og --netrc-file "$netrc" $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
        done;
    elif command -v wget >/dev/null 2>&1; then
        # We can't use wget to poke provider server to get info whether or not URS was integrated without download at least one of the files.
        echo
        echo "WARNING: Can't find curl, use wget instead."
        echo "WARNING: Script may not correctly identify Earthdata Login integrations."
        echo
        setup_auth_wget
        while read -r line; do
        wget --load-cookies "$cookiejar" --save-cookies "$cookiejar" --keep-session-cookies -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
        done;
    else
        exit_with_error "Error: Could not find a command-line downloader.  Please install curl or wget"
    fi
}

fetch_urls <<'EDSCEOF'
  ftp://l5ftl01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2017.02.01/MISR_AM1_CGAS_FEB_2017_F15_0031.hdf
ftp://l5ftl01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2017.01.01/MISR_AM1_CGAS_JAN_2017_F15_0031.hdf
ftp://l5ftl01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2016.12.01/MISR_AM1_CGAS_DEC_2016_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2016.11.01/MISR_AM1_CGAS_NOV_2016_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2016.10.01/MISR_AM1_CGAS_OCT_2016_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2016.09.01/MISR_AM1_CGAS_SEP_2016_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2016.08.01/MISR_AM1_CGAS_AUG_2016_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2016.07.01/MISR_AM1_CGAS_JUL_2016_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2016.06.01/MISR_AM1_CGAS_JUN_2016_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2016.05.01/MISR_AM1_CGAS_MAY_2016_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2016.04.01/MISR_AM1_CGAS_APR_2016_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2016.03.01/MISR_AM1_CGAS_MAR_2016_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2016.02.01/MISR_AM1_CGAS_FEB_2016_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2016.01.01/MISR_AM1_CGAS_JAN_2016_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2015.12.01/MISR_AM1_CGAS_DEC_2015_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2015.11.01/MISR_AM1_CGAS_NOV_2015_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2015.10.01/MISR_AM1_CGAS_OCT_2015_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2015.09.01/MISR_AM1_CGAS_SEP_2015_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2015.08.01/MISR_AM1_CGAS_AUG_2015_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2015.07.01/MISR_AM1_CGAS_JUL_2015_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2015.06.01/MISR_AM1_CGAS_JUN_2015_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2015.05.01/MISR_AM1_CGAS_MAY_2015_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2015.04.01/MISR_AM1_CGAS_APR_2015_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2015.03.01/MISR_AM1_CGAS_MAR_2015_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2015.02.01/MISR_AM1_CGAS_FEB_2015_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2015.01.01/MISR_AM1_CGAS_JAN_2015_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2014.12.01/MISR_AM1_CGAS_DEC_2014_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2014.11.01/MISR_AM1_CGAS_NOV_2014_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2014.10.01/MISR_AM1_CGAS_OCT_2014_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2014.09.01/MISR_AM1_CGAS_SEP_2014_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2014.08.01/MISR_AM1_CGAS_AUG_2014_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2014.07.01/MISR_AM1_CGAS_JUL_2014_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2014.06.01/MISR_AM1_CGAS_JUN_2014_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2014.05.01/MISR_AM1_CGAS_MAY_2014_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2014.04.01/MISR_AM1_CGAS_APR_2014_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2014.03.01/MISR_AM1_CGAS_MAR_2014_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2014.02.01/MISR_AM1_CGAS_FEB_2014_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2014.01.01/MISR_AM1_CGAS_JAN_2014_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2013.12.01/MISR_AM1_CGAS_DEC_2013_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2013.11.01/MISR_AM1_CGAS_NOV_2013_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2013.10.01/MISR_AM1_CGAS_OCT_2013_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2013.09.01/MISR_AM1_CGAS_SEP_2013_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2013.08.01/MISR_AM1_CGAS_AUG_2013_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2013.07.01/MISR_AM1_CGAS_JUL_2013_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2013.06.01/MISR_AM1_CGAS_JUN_2013_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2013.05.01/MISR_AM1_CGAS_MAY_2013_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2013.04.01/MISR_AM1_CGAS_APR_2013_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2013.03.01/MISR_AM1_CGAS_MAR_2013_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2013.02.01/MISR_AM1_CGAS_FEB_2013_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2013.01.01/MISR_AM1_CGAS_JAN_2013_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2012.12.01/MISR_AM1_CGAS_DEC_2012_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2012.11.01/MISR_AM1_CGAS_NOV_2012_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2012.10.01/MISR_AM1_CGAS_OCT_2012_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2012.09.01/MISR_AM1_CGAS_SEP_2012_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2012.08.01/MISR_AM1_CGAS_AUG_2012_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2012.07.01/MISR_AM1_CGAS_JUL_2012_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2012.06.01/MISR_AM1_CGAS_JUN_2012_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2012.05.01/MISR_AM1_CGAS_MAY_2012_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2012.04.01/MISR_AM1_CGAS_APR_2012_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2012.03.01/MISR_AM1_CGAS_MAR_2012_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2012.02.01/MISR_AM1_CGAS_FEB_2012_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2012.01.01/MISR_AM1_CGAS_JAN_2012_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2011.12.01/MISR_AM1_CGAS_DEC_2011_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2011.11.01/MISR_AM1_CGAS_NOV_2011_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2011.10.01/MISR_AM1_CGAS_OCT_2011_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2011.09.01/MISR_AM1_CGAS_SEP_2011_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2011.08.01/MISR_AM1_CGAS_AUG_2011_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2011.07.01/MISR_AM1_CGAS_JUL_2011_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2011.06.01/MISR_AM1_CGAS_JUN_2011_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2011.05.01/MISR_AM1_CGAS_MAY_2011_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2011.04.01/MISR_AM1_CGAS_APR_2011_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2011.03.01/MISR_AM1_CGAS_MAR_2011_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2011.02.01/MISR_AM1_CGAS_FEB_2011_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2011.01.01/MISR_AM1_CGAS_JAN_2011_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2010.12.01/MISR_AM1_CGAS_DEC_2010_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2010.11.01/MISR_AM1_CGAS_NOV_2010_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2010.10.01/MISR_AM1_CGAS_OCT_2010_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2010.09.01/MISR_AM1_CGAS_SEP_2010_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2010.08.01/MISR_AM1_CGAS_AUG_2010_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2010.07.01/MISR_AM1_CGAS_JUL_2010_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2010.06.01/MISR_AM1_CGAS_JUN_2010_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2010.05.01/MISR_AM1_CGAS_MAY_2010_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2010.04.01/MISR_AM1_CGAS_APR_2010_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2010.03.01/MISR_AM1_CGAS_MAR_2010_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2010.02.01/MISR_AM1_CGAS_FEB_2010_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2010.01.01/MISR_AM1_CGAS_JAN_2010_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2009.12.01/MISR_AM1_CGAS_DEC_2009_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2009.11.01/MISR_AM1_CGAS_NOV_2009_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2009.10.01/MISR_AM1_CGAS_OCT_2009_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2009.09.01/MISR_AM1_CGAS_SEP_2009_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2009.08.01/MISR_AM1_CGAS_AUG_2009_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2009.07.01/MISR_AM1_CGAS_JUL_2009_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2009.06.01/MISR_AM1_CGAS_JUN_2009_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2009.05.01/MISR_AM1_CGAS_MAY_2009_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2009.04.01/MISR_AM1_CGAS_APR_2009_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2009.03.01/MISR_AM1_CGAS_MAR_2009_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2009.02.01/MISR_AM1_CGAS_FEB_2009_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2009.01.01/MISR_AM1_CGAS_JAN_2009_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2008.12.01/MISR_AM1_CGAS_DEC_2008_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2008.11.01/MISR_AM1_CGAS_NOV_2008_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2008.10.01/MISR_AM1_CGAS_OCT_2008_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2008.09.01/MISR_AM1_CGAS_SEP_2008_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2008.08.01/MISR_AM1_CGAS_AUG_2008_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2008.07.01/MISR_AM1_CGAS_JUL_2008_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2008.06.01/MISR_AM1_CGAS_JUN_2008_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2008.05.01/MISR_AM1_CGAS_MAY_2008_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2008.04.01/MISR_AM1_CGAS_APR_2008_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2008.03.01/MISR_AM1_CGAS_MAR_2008_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2008.02.01/MISR_AM1_CGAS_FEB_2008_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2008.01.01/MISR_AM1_CGAS_JAN_2008_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2007.12.01/MISR_AM1_CGAS_DEC_2007_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2007.11.01/MISR_AM1_CGAS_NOV_2007_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2007.10.01/MISR_AM1_CGAS_OCT_2007_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2007.09.01/MISR_AM1_CGAS_SEP_2007_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2007.08.01/MISR_AM1_CGAS_AUG_2007_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2007.07.01/MISR_AM1_CGAS_JUL_2007_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2007.06.01/MISR_AM1_CGAS_JUN_2007_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2007.05.01/MISR_AM1_CGAS_MAY_2007_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2007.04.01/MISR_AM1_CGAS_APR_2007_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2007.03.01/MISR_AM1_CGAS_MAR_2007_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2007.02.01/MISR_AM1_CGAS_FEB_2007_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2007.01.01/MISR_AM1_CGAS_JAN_2007_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2006.12.01/MISR_AM1_CGAS_DEC_2006_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2006.11.01/MISR_AM1_CGAS_NOV_2006_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2006.10.01/MISR_AM1_CGAS_OCT_2006_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2006.09.01/MISR_AM1_CGAS_SEP_2006_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2006.08.01/MISR_AM1_CGAS_AUG_2006_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2006.07.01/MISR_AM1_CGAS_JUL_2006_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2006.06.01/MISR_AM1_CGAS_JUN_2006_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2006.05.01/MISR_AM1_CGAS_MAY_2006_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2006.04.01/MISR_AM1_CGAS_APR_2006_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2006.03.01/MISR_AM1_CGAS_MAR_2006_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2006.02.01/MISR_AM1_CGAS_FEB_2006_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2006.01.01/MISR_AM1_CGAS_JAN_2006_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2005.12.01/MISR_AM1_CGAS_DEC_2005_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2005.11.01/MISR_AM1_CGAS_NOV_2005_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2005.10.01/MISR_AM1_CGAS_OCT_2005_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2005.09.01/MISR_AM1_CGAS_SEP_2005_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2005.08.01/MISR_AM1_CGAS_AUG_2005_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2005.07.01/MISR_AM1_CGAS_JUL_2005_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2005.06.01/MISR_AM1_CGAS_JUN_2005_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2005.05.01/MISR_AM1_CGAS_MAY_2005_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2005.04.01/MISR_AM1_CGAS_APR_2005_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2005.03.01/MISR_AM1_CGAS_MAR_2005_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2005.02.01/MISR_AM1_CGAS_FEB_2005_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2005.01.01/MISR_AM1_CGAS_JAN_2005_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2004.12.01/MISR_AM1_CGAS_DEC_2004_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2004.11.01/MISR_AM1_CGAS_NOV_2004_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2004.10.01/MISR_AM1_CGAS_OCT_2004_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2004.09.01/MISR_AM1_CGAS_SEP_2004_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2004.08.01/MISR_AM1_CGAS_AUG_2004_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2004.07.01/MISR_AM1_CGAS_JUL_2004_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2004.06.01/MISR_AM1_CGAS_JUN_2004_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2004.05.01/MISR_AM1_CGAS_MAY_2004_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2004.04.01/MISR_AM1_CGAS_APR_2004_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2004.03.01/MISR_AM1_CGAS_MAR_2004_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2004.02.01/MISR_AM1_CGAS_FEB_2004_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2004.01.01/MISR_AM1_CGAS_JAN_2004_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2003.12.01/MISR_AM1_CGAS_DEC_2003_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2003.11.01/MISR_AM1_CGAS_NOV_2003_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2003.10.01/MISR_AM1_CGAS_OCT_2003_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2003.09.01/MISR_AM1_CGAS_SEP_2003_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2003.08.01/MISR_AM1_CGAS_AUG_2003_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2003.07.01/MISR_AM1_CGAS_JUL_2003_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2003.06.01/MISR_AM1_CGAS_JUN_2003_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2003.05.01/MISR_AM1_CGAS_MAY_2003_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2003.04.01/MISR_AM1_CGAS_APR_2003_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2003.03.01/MISR_AM1_CGAS_MAR_2003_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2003.02.01/MISR_AM1_CGAS_FEB_2003_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2003.01.01/MISR_AM1_CGAS_JAN_2003_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2002.12.01/MISR_AM1_CGAS_DEC_2002_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2002.11.01/MISR_AM1_CGAS_NOV_2002_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2002.10.01/MISR_AM1_CGAS_OCT_2002_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2002.09.01/MISR_AM1_CGAS_SEP_2002_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2002.08.01/MISR_AM1_CGAS_AUG_2002_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2002.07.01/MISR_AM1_CGAS_JUL_2002_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2002.06.01/MISR_AM1_CGAS_JUN_2002_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2002.05.01/MISR_AM1_CGAS_MAY_2002_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2002.04.01/MISR_AM1_CGAS_APR_2002_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2002.03.01/MISR_AM1_CGAS_MAR_2002_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2002.02.01/MISR_AM1_CGAS_FEB_2002_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2002.01.01/MISR_AM1_CGAS_JAN_2002_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2001.12.01/MISR_AM1_CGAS_DEC_2001_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2001.11.01/MISR_AM1_CGAS_NOV_2001_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2001.10.01/MISR_AM1_CGAS_OCT_2001_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2001.09.01/MISR_AM1_CGAS_SEP_2001_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2001.08.01/MISR_AM1_CGAS_AUG_2001_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2001.07.01/MISR_AM1_CGAS_JUL_2001_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2001.06.01/MISR_AM1_CGAS_JUN_2001_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2001.05.01/MISR_AM1_CGAS_MAY_2001_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2001.04.01/MISR_AM1_CGAS_APR_2001_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2001.03.01/MISR_AM1_CGAS_MAR_2001_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2001.02.01/MISR_AM1_CGAS_FEB_2001_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2001.01.01/MISR_AM1_CGAS_JAN_2001_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2000.12.01/MISR_AM1_CGAS_DEC_2000_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2000.11.01/MISR_AM1_CGAS_NOV_2000_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2000.10.01/MISR_AM1_CGAS_OCT_2000_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2000.09.01/MISR_AM1_CGAS_SEP_2000_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2000.08.01/MISR_AM1_CGAS_AUG_2000_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2000.07.01/MISR_AM1_CGAS_JUL_2000_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2000.06.01/MISR_AM1_CGAS_JUN_2000_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2000.05.01/MISR_AM1_CGAS_MAY_2000_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2000.04.01/MISR_AM1_CGAS_APR_2000_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2000.03.01/MISR_AM1_CGAS_MAR_2000_F15_0031.hdf
ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2000.02.01/MISR_AM1_CGAS_FEB_2000_F15_0031.hdf
EDSCEOF
