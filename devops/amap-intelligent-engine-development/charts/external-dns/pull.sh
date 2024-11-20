currdir=`basename "$PWD"`

mkdir ../tmp_$currdir
##buckup custom files
cp values-dm3.yaml  ../tmp_$currdir/
cp pull.sh  ../tmp_$currdir/
# clean folder
rm -r *

##restore custom files
cp -r ../tmp_$currdir/* .

#delete backup folder
rm -r ../tmp_$currdir

## pull chart 
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
helm repo update
#diplay latest version
helm search repo external-dns/external-dns
#diplay history 
helm search repo -l external-dns/external-dns
helm pull external-dns/external-dns --version=1.13.0  --untar 

mv -f $currdir/*  ../$currdir
rm -r $currdir
