<!doctype html>
<html>
<head><title>{$title}</title></head>
<body>
<h1>{$title}</h1>
<form>
{html_options name="fruit"
    values=$ids output=$names selected=`$smarty.get.fruit` }
<input type="submit" />
</form>
</body>
</html>
