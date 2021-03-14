echo "Deploy started ..."
echo "Building Sites ..."
hugo
echo "Publishing contents ..."
cd public 
git add .
git commit -m "Rebuilding site"
git push origin main
cd ..
git push origin main
echo "Finished"