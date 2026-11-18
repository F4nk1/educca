package service

import (
	"context"
	"database/sql"
	"errors"

	"golang.org/x/crypto/bcrypt"

	"github.com/F4nk1/educca/backend/source/common"
	"github.com/F4nk1/educca/backend/source/model"
)

func (s *service) Login(ctx context.Context, identificador, password string) (*model.Persona, error) {
	var p model.Persona
	var passwordHash string

	err := s.conn.Db.QueryRowContext(
		ctx,
		`SELECT id, dni, nombres, apellidos, email, password_hash, activo FROM fn_auth_login($1)`,
		identificador,
	).Scan(&p.Id, &p.Dni, &p.Nombres, &p.Apellidos, &p.Email, &passwordHash, &p.Activo)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrInvalidCredentials
		}
		return nil, classifyError(err, false)
	}

	if !p.Activo {
		return nil, ErrInactiveUser
	}

	if err := bcrypt.CompareHashAndPassword([]byte(passwordHash), []byte(password)); err != nil {
		return nil, ErrInvalidCredentials
	}

	return &p, nil
}

func (s *service) GetPersonaRolesPermisos(ctx context.Context, personaId int64) ([]string, []string, error) {
	roles, err := s.scanStringSlice(ctx, `SELECT nombre FROM fn_persona_roles_nombres($1)`, personaId)
	if err != nil {
		return nil, nil, err
	}
	permisos, err := s.scanStringSlice(ctx, `SELECT clave FROM fn_persona_permisos_claves($1)`, personaId)
	if err != nil {
		return nil, nil, err
	}
	return roles, permisos, nil
}

func (s *service) HasPermission(ctx context.Context, personaId int64, permiso string) (bool, error) {
	if permiso == common.PermAuthenticated {
		var active bool
		err := s.conn.Db.QueryRowContext(
			ctx,
			`SELECT EXISTS (SELECT 1 FROM persona WHERE id = $1 AND activo = TRUE AND anonimizado = FALSE)`,
			personaId,
		).Scan(&active)
		if err != nil {
			return false, classifyError(err, false)
		}
		return active, nil
	}

	var allowed bool
	err := s.conn.Db.QueryRowContext(ctx, `SELECT fn_persona_tiene_permiso($1, $2)`, personaId, permiso).Scan(&allowed)
	if err != nil {
		return false, classifyError(err, false)
	}
	return allowed, nil
}
