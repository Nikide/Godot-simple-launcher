
# Godot Simple Launcher
The Godot Simple Launcher uses an S3 bucket to download and check for version changes based on the S3 ETag.

---

## How to Use
First, you need an S3 bucket.

Push your `game.exe` file to the bucket with the **public-read** access control list (ACL).


```bash
aws s3 cp <local-file-path> s3://<your-bucket-name>/<destination-key> --acl public-read
```

You'll get a link like `bucket.type.s3-provider.com/game.exe`.

In the **main.gd** script, set the `host` and `file_name` variables:

```gdscript
var host = "bucket.hb.ru-msk.vkcloud-storage.ru"
var file_name = "game.exe"
```

Run the project to test it\!

The game file is saved to the local user folder at `%APPDATA%\Godot\app_userdata\simple_launcher`.

-----

## How It Works

S3 files have a unique **ETag**. When you push a new version of a file, the ETag will regenerate even if the filename remains the same. To update your game, you just need to push the new version of the file with the same filename to the S3 bucket.

When the launcher downloads the file, it writes the ETag to `etag.txt` and checks it on every subsequent launch. If the ETag is different, the launcher will redownload the file and write the new ETag.

After downloading or checking the ETag, the launcher runs `game.exe` and then closes.
