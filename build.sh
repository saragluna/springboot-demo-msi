mvn clean package -DskipTests
cp target/demo-0.0.1-SNAPSHOT.jar app.jar

git co jar
git add app.jar
git cm 'deploy'


git push

git co master

