#!/usr/bin/env groovy
// Helper script to load .env variables into Jenkins environment
// Usage: load('load-env.groovy')

def loadEnv() {
    def envFile = readFile('.env')
    def envVars = [:]
    
    envFile.split('\n').each { line ->
        line = line.trim()
        if (!line.startsWith('#') && line.contains('=')) {
            def parts = line.split('=', 2)
            def key = parts[0].trim()
            def value = parts[1].trim()
            // Remove quotes if present
            if (value.startsWith('"') && value.endsWith('"')) {
                value = value[1..-2]
            } else if (value.startsWith("'") && value.endsWith("'")) {
                value = value[1..-2]
            }
            envVars[key] = value
            env[key] = value
        }
    }
    
    return envVars
}

return this
