---
title: Cloudflare R2 Pre-signed URL Cross-Origin Issue
date: 2024-10-20 10:42:22
tags:
 - bugs
---

## 1. Problem description

获取到Cloudflare R2的Pre-signed URL后，使用网页上传文件时，总是返回各自各样的错误, 在网页遇到的是跨域问题, 总是报错说 pre flight request failed. 

查了一圈, 说是请求头的问题, 需要在平台设置 `Access-Control-Allow-Origin` 和 `Access-Control-Allow-Headers` 等请求头. 后面设置了, 也无济于事. 有的说得包含 Content-type 头, 即若前端通过pre-signed url上传文件, 设置了 Content-Type 头, 则后端请求pre-signed url时, 也必须设置 Content-Type 头. 什么必须要同一个方法 PUT, 都设置 都不行, 

后来使用 SwiftUI 开发, 想着换个环境, 就没有跨域问题了吧, 可是还是报错, 报错信息是 401, 没有权限. 

## 2. Problem analysis

结果问题出现在 Cloudflare R2 和 AWS S3 签名版本兼容问题上:

> Cloudflare R2 requires presigned URLs to be generated using AWS Signature Version 4. Any other signature version will result in authentication failures.

这不, 什么都不用改, 只要把签名版本改成4就可以了:

```csharp
public class R2Service
{
    private readonly IAmazonS3 _r2Client;
    private readonly string _bucketName;

    public R2Service(IConfiguration configuration)
    {
        var accessKey = configuration["AWS:S3:AccessKey"];
        var secretKey = configuration["AWS:S3:SecretKey"];
        var endpoint = configuration["AWS:S3:Endpoint"];
        _bucketName = configuration["AWS:S3:BucketName"] 
                      ?? throw new ArgumentNullException(nameof(configuration), "AWS:S3:BucketName is not configured");

        var config = new AmazonS3Config { 
            ServiceURL = endpoint,
            SignatureVersion = "4", // 注意这里
            ForcePathStyle = true,  // 重要！R2 需要这个配置
            AuthenticationRegion = "auto",
        };

        _r2Client = new AmazonS3Client(accessKey, secretKey, config);
    }

    public async Task<(string PresignedUrl, string ImageUrl)> GeneratePresignedUrl(string fileName, string fileType)
    {
        var key = $"{Guid.NewGuid()}-{fileName}";
        var request = new GetPreSignedUrlRequest
        {
            BucketName = _bucketName,
            Key = key,
            Verb = HttpVerb.PUT, // 请求的签名方法是PUT, 所以客户端上传文件时, 也必须使用PUT方法
            ContentType = fileType,
            Expires = DateTime.Now.AddMinutes(50),
        };
        
        var presignedUrl = await _r2Client.GetPreSignedURLAsync(request);
        var imageUrl = $"{_r2Client.Config.ServiceURL}/{_bucketName}/{key}";

        return (presignedUrl, imageUrl);
    }
}
```

前端代码:

```js
registerForm.addEventListener('submit', async (e) => {
    ...
    const file = document.getElementById('profileImage').files[0];
    try {
        if (file) {
            const presignedUrlResponse = await axios.get(`${API_URL}/api/auth/presigned-url`, {
                params: { fileName: file.name, fileType: file.type }
            });
            const { presignedUrl, imageUrl } = presignedUrlResponse.data;

            console.log("Received presigned URL:", presignedUrl);

            try {
                // 注意是PUT方法, 也包含了Content-Type头
                await axios.put(presignedUrl, file, {
                    headers: {'Content-Type': file.type}
                });
                userData.profileImage = imageUrl;
            } catch (uploadError) {
                console.error("Error uploading image:", uploadError);
                return
            }
        }

        await axios.post(`${API_URL}/api/auth/register`, userData, {
            headers: {'Content-Type': 'application/json'}
        });
        console.log("User registered successfully");
    } catch (error) {
        console.error("Registration error:", error);
        handleAxiosError(error, 'register');
    }
});
```
