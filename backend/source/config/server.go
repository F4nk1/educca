package config

type Server struct {
	Port          string `json:"port"`
	AccessSecret  string `json:"-"`
	RefreshSecret string `json:"-"`
}
