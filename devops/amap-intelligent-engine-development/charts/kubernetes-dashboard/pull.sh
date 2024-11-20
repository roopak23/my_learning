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
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm repo update
#diplay latest version
helm search repo kubernetes-dashboard/kubernetes-dashboard
#diplay history 
helm search repo -l kubernetes-dashboard/kubernetes-dashboard
helm pull kubernetes-dashboard/kubernetes-dashboard --version=6.0.8  --untar 

mv -f $currdir/*  ../$currdir
rm -r $currdir
