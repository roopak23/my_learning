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
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm repo update
#diplay latest version
helm search repo autoscaler/cluster-autoscaler
#diplay history 
helm search repo -l autoscaler/cluster-autoscaler
helm pull autoscaler/cluster-autoscaler  --version=9.29.1 --untar 

mv -f $currdir/*  ../$currdir
rm -r $currdir