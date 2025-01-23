---
title: NuGet Package Management
date: 2024-12-03 19:42:36
tags:
 - c#
---

Create new project with dotnet CLI

```bash
$dotnet new list

$dotnet new <template> -n <project-name>
```

----

```bash
# -n project name
$dotnet new console -n tts-service-csharp
$ls 
Program.cs                obj                       tts-service-csharp.sln
bin                       tts-service-csharp.csproj
# install a package for current project
$ dotnet add package Microsoft.CognitiveServices.Speech
```

- `Program.cs`: contains the `Main` method where your program starts executing
- `bin` folder (binary): contains the compiled output of your program, after building, you'll find your executable (.exe) and other compiled files here. 
- `obj` folder (objects): contains temporary files used during compilation, these files can be safely deleted and will be recreated during the next build. 
- `tts-service-csharp.csproj`: the project file that defines your project settings, contains project configuration, dependencies, target framework
- `ts-service-csharp.sln` (solution): a solution file that can contain multiple related projects, useful when your application grows and needs to be split into multiple projects. 

---

`tts-service-csharp.csproj`:

```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net8.0</TargetFramework>
    <RootNamespace>tts_service_csharp</RootNamespace>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.CognitiveServices.Speech" Version="1.41.1" />
  </ItemGroup>

</Project>
```

> All .NET projects list their dependencies in the `.csproj` file. If you have worked with JavaScript before, think of it like a `package.json` file. 
>
> The `.csproj` file also contains all the information that .NET tooling needs to build the project. It includes the type of the project being built (console, web, desktop, etc.), the platform this project targets and any dependencies on other projects or 3rd party libraries.
>
> `<OutputType>Exe</OutputType>` stands for: Console application

-----

```bash
$dotnet add package Microsoft.CognitiveServices.Speech
```

1. The `dotnet` CLI first checks if the current directory contains a valid .NET project file `*.csproj`

2. It then connects to the default package source (nuget.org) to erify the package exists

3. The CLI resolves dependencies by creating a dependency graph to ensure version compatibility

4. It then:

   - Downloads the package and its dependencies to the Global NuGet cache (typically in `~/.nuget/packages`)

   - Adds a PackageReference element to your project file like:

   ```xml
   <PackageReference Include="Microsoft.CognitiveServices.Speech" Version="x.x.x" />
   ```
   - Updates the project's obj/project.assets.json file which tracks all package references

5. Finally, it performs a restore operation to ensure all dependencies are available locally

The package gets installed in Global NuGet cache: `~/.nuget/packages/`, this is shared across all projects on your machine, packages here don't get deleted when you delete a project, if you want to clean up unused packages from the global cache, you can:

```bash
$dotnet nuget locals all --clear

# Or manually delete packages from:
~/.nuget/packages/microsoft.cognitiveservices.speech
```

