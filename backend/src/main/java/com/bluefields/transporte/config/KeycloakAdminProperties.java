package com.bluefields.transporte.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "transporte.keycloak")
public class KeycloakAdminProperties {

    private String serverUrl = "http://127.0.0.1:8180";
    private String realm = "transporte-bluefields";
    private String adminRealm = "master";
    private String adminClientId = "admin-cli";
    private String adminUsername = "admin";
    private String adminPassword = "admin";
    private boolean enabled = true;

    public String getServerUrl() { return serverUrl; }
    public void setServerUrl(String serverUrl) { this.serverUrl = serverUrl; }
    public String getRealm() { return realm; }
    public void setRealm(String realm) { this.realm = realm; }
    public String getAdminRealm() { return adminRealm; }
    public void setAdminRealm(String adminRealm) { this.adminRealm = adminRealm; }
    public String getAdminClientId() { return adminClientId; }
    public void setAdminClientId(String adminClientId) { this.adminClientId = adminClientId; }
    public String getAdminUsername() { return adminUsername; }
    public void setAdminUsername(String adminUsername) { this.adminUsername = adminUsername; }
    public String getAdminPassword() { return adminPassword; }
    public void setAdminPassword(String adminPassword) { this.adminPassword = adminPassword; }
    public boolean isEnabled() { return enabled; }
    public void setEnabled(boolean enabled) { this.enabled = enabled; }
}
