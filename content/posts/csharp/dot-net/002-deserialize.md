---
title: System.Text.Json
date: 2024-07-27 19:42:36
tags:
 - c#
---

Any JSON properties that aren't represented in your class are ignored [by default](https://learn.microsoft.com/en-us/dotnet/standard/serialization/system-text-json/missing-members). Also, if any properties on the type are [required](https://learn.microsoft.com/en-us/dotnet/standard/serialization/system-text-json/required-properties) but not present in the JSON payload, deserialization will fail. 

Starting in .NET 7, you can mark certain properties to signify that they must be present in the JSON payload for deserialization to succeed. If one or more of these required properties is not present, the [JsonSerializer.Deserialize](https://learn.microsoft.com/en-us/dotnet/api/system.text.json.jsonserializer.deserialize) methods throw a [JsonException](https://learn.microsoft.com/en-us/dotnet/api/system.text.json.jsonexception).There are three ways to mark a property or field as required for JSON deserialization:

- By adding the [required modifier](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/keywords/required), which is new in C# 11.
- By annotating it with [JsonRequiredAttribute](https://learn.microsoft.com/en-us/dotnet/api/system.text.json.serialization.jsonrequiredattribute), which is new in .NET 7.
- By modifying the [JsonPropertyInfo.IsRequired](https://learn.microsoft.com/en-us/dotnet/api/system.text.json.serialization.metadata.jsonpropertyinfo.isrequired#system-text-json-serialization-metadata-jsonpropertyinfo-isrequired) property of the contract model, which is new in .NET 7.

----

Deserialization behavior: https://arc.net/l/quote/rlyayhmm

- By default, property name matching is case-sensitive.
- Non-public constructors are ignored by the serializer. ??
- ...

When you use System.Text.Json indirectly in an ASP.NET Core app, some default behaviors are different. For more information, see [Web defaults for JsonSerializerOptions](https://learn.microsoft.com/en-us/dotnet/standard/serialization/system-text-json/configure-options#web-defaults-for-jsonserializeroptions).

The following options have different defaults for web apps:

- [PropertyNameCaseInsensitive](https://learn.microsoft.com/en-us/dotnet/api/system.text.json.jsonserializeroptions.propertynamecaseinsensitive) = `true`
- [PropertyNamingPolicy](https://learn.microsoft.com/en-us/dotnet/api/system.text.json.jsonserializeroptions.propertynamingpolicy#system-text-json-jsonserializeroptions-propertynamingpolicy) = [CamelCase](https://learn.microsoft.com/en-us/dotnet/api/system.text.json.jsonnamingpolicy.camelcase#system-text-json-jsonnamingpolicy-camelcase)
- [NumberHandling](https://learn.microsoft.com/en-us/dotnet/api/system.text.json.jsonserializeroptions.numberhandling) = [AllowReadingFromString](https://learn.microsoft.com/en-us/dotnet/api/system.text.json.serialization.jsonnumberhandling#system-text-json-serialization-jsonnumberhandling-allowreadingfromstring)

