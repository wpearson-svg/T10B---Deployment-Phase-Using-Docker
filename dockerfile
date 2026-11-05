# syntax=docker/dockerfile:1

# ---------- Build stage ----------
# Full .NET 10 SDK image, used only to restore and publish the app.
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy the project file first and restore, so this layer is cached
# until package references change.
COPY ContainerizationTest/ContainerizationTest.csproj ContainerizationTest/
RUN dotnet restore ContainerizationTest/ContainerizationTest.csproj

# Copy the rest of the source and publish a Release build.
COPY ContainerizationTest/ ContainerizationTest/
WORKDIR /src/ContainerizationTest
RUN dotnet publish ContainerizationTest.csproj \
    -c Release \
    -o /app/publish \
    --no-restore \
    /p:UseAppHost=false

# ---------- Runtime stage ----------
# Smaller ASP.NET Core 10 runtime image (no SDK).
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app

# .NET 8+ images listen on port 8080 by default.
ENV ASPNETCORE_HTTP_PORTS=8080 \
    ASPNETCORE_ENVIRONMENT=Production
EXPOSE 8080

COPY --from=build /app/publish .

# Run as the built-in non-root "app" user.
USER $APP_UID

ENTRYPOINT ["dotnet", "ContainerizationTest.dll"]
