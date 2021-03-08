echo "Deploy started ..."
echo "Deleting public directory ..."
rd public
echo "Building Sites ..."
hugo
echo "Publishing contents ..."
cd public 
git add .
git commit -m "Rebuilding site"
git push origin main
cd ..
rd public
git push origin main
echo "Finished"