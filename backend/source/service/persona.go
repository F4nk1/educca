package service

import (
	"context"
	"database/sql"

	"golang.org/x/crypto/bcrypt"

	"github.com/F4nk1/educca/backend/source/model"
)

func scanPersona(s interface{ Scan(...any) error }) (model.Persona, error) {
	var p model.Persona
	err := s.Scan(&p.Id, &p.Dni, &p.Nombres, &p.Apellidos, &p.Sexo, &p.FechaNacimiento, &p.Telefono, &p.Email, &p.Activo)
	return p, err
}

func (s *service) ListPersonas(ctx context.Context) ([]model.Persona, error) {
	return queryRows(
		ctx,
		s.conn.Db,
		`SELECT id, dni, nombres, apellidos, sexo, fecha_nacimiento, telefono, email, activo FROM fn_persona_listar()`,
		func(rows *sql.Rows) (model.Persona, error) { return scanPersona(rows) },
	)
}

func (s *service) GetPersona(ctx context.Context, id int64) (*model.Persona, error) {
	p, err := scanPersona(s.conn.Db.QueryRowContext(
		ctx,
		`SELECT id, dni, nombres, apellidos, sexo, fecha_nacimiento, telefono, email, activo FROM fn_persona_obtener($1)`,
		id,
	))
	if err != nil {
		return nil, classifyError(err, false)
	}
	return &p, nil
}

func (s *service) CreatePersona(ctx context.Context, p *model.Persona, password string) (int64, error) {
	var hashPtr *string
	if password != "" {
		hashed, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
		if err != nil {
			return 0, err
		}
		h := string(hashed)
		hashPtr = &h
	}

	var id int64
	err := s.conn.Db.QueryRowContext(
		ctx,
		`SELECT fn_persona_crear($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
		p.Dni, p.Nombres, p.Apellidos, p.Sexo, p.FechaNacimiento, p.Telefono, p.Email, hashPtr, p.Activo,
	).Scan(&id)
	if err != nil {
		return 0, classifyError(err, false)
	}
	return id, nil
}

func (s *service) UpdatePersona(ctx context.Context, p *model.Persona) error {
	return s.execBool(
		ctx,
		false,
		`SELECT fn_persona_actualizar($1, $2, $3, $4, $5, $6, $7, $8)`,
		p.Id, p.Dni, p.Nombres, p.Apellidos, p.Sexo, p.FechaNacimiento, p.Telefono, p.Email,
	)
}

func (s *service) SetPersonaActivo(ctx context.Context, id int64, activo bool) error {
	return s.execBool(ctx, false, `SELECT fn_persona_cambiar_activo($1, $2)`, id, activo)
}

func (s *service) SetPersonaPassword(ctx context.Context, id int64, password string) error {
	hashed, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	return s.execBool(ctx, false, `SELECT fn_persona_cambiar_password($1, $2)`, id, string(hashed))
}

func (s *service) ListPersonaRoles(ctx context.Context, personaId int64) ([]model.Rol, error) {
	return queryRows(
		ctx,
		s.conn.Db,
		`SELECT id, nombre, descripcion FROM fn_persona_listar_roles($1)`,
		func(rows *sql.Rows) (model.Rol, error) { return scanRol(rows) },
		personaId,
	)
}

func (s *service) AssignPersonaRol(ctx context.Context, personaId int64, rolId int16) error {
	_, err := s.conn.Db.ExecContext(ctx, `SELECT fn_persona_asignar_rol($1, $2)`, personaId, rolId)
	return classifyError(err, false)
}

func (s *service) RemovePersonaRol(ctx context.Context, personaId int64, rolId int16) error {
	return s.execBool(ctx, true, `SELECT fn_persona_quitar_rol($1, $2)`, personaId, rolId)
}
