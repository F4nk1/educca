package config

type Server struct {
	Port                 string   `json:"port"`
	Env                  string   `json:"env"`
	AccessSecret         string   `json:"-"`
	RefreshSecret        string   `json:"-"`
	QRSecret             string   `json:"-"`
	QRTTLSeconds         int      `json:"qr_ttl_seconds"`
	PrivacyPolicyVersion string   `json:"privacy_policy_version"`
	AllowedOrigins       []string `json:"allowed_origins"`
}
