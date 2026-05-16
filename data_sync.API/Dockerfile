FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY ["data_sync.API.csproj", "./"]
RUN dotnet restore "./data_sync.API.csproj"

COPY . .
RUN dotnet publish "./data_sync.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app

COPY --from=build /app/publish .

EXPOSE 8080

# Die API lauscht nur auf dem internen Container-Port; HTTPS macht Caddy.
ENV ASPNETCORE_URLS=http://+:8080

ENTRYPOINT ["dotnet", "data_sync.API.dll"]
