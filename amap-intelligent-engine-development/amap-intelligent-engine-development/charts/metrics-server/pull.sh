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
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update
#diplay latest version
helm search repo metrics-server/metrics-server
#diplay history 
helm search repo -l metrics-server/metrics-server
helm pull metrics-server/metrics-server --verions=3.10.0  --untar 

mv -f $currdir/*  ../$currdir
rm -r $currdir
