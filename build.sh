mvn clean package -DskipTests

git co jar

rm app.jar

cp target/demo-0.0.1-SNAPSHOT.jar app.jar
git add app.jar
git cm 'deploy'

git push

git co master

