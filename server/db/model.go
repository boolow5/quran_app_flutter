package db

type Model interface {
	TableName() string
	SetID(id uint64)
	GetID() uint64
}

func GetOffset(page, pageSize *uint64) *uint64 {
	offset := (*page - 1) * *pageSize
	return &offset
}
