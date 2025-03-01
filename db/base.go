package db

import (
	"log"
	"time"

	uuid "github.com/gofrs/uuid/v5"
	"gorm.io/gorm"
)

// Base is
type Base struct {
	ID        string `sql:"type:uuid;primary_key"`
	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt *time.Time `gorm:"index"`
}

// BeforeCreate
func (base *Base) BeforeCreate(tx *gorm.DB) error {
	u2, err := uuid.NewV4()
	if err != nil {
		log.Fatalf("failed to generate UUID: %v", err)
	}
	tx.Statement.SetColumn("ID", u2.String())
	return nil
}
