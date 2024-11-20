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
helm repo add eks https://aws.github.io/eks-charts
helm repo update
#diplay latest version
helm search repo eks/aws-load-balancer-controller
#diplay history 
helm search repo -l eks/aws-load-balancer-controller
helm pull  eks/aws-load-balancer-controller --version=1.5.3 --untar 

mv -f $currdir/*  ../$currdir
rm -r $currdir