
#!/bin/bash
sudo apt-get update

sudo apt-get install -y apache2-bin
sudo apt-get install -y apache2

cat > index.html <<END
<!DOCTYPE html> 
<html>
	<body>
		<h1>Hello world</h1>		
	</body>
</html>
END

sudo rm /var/www/html/index.html
sudo mv index.html /var/www/html/index.html