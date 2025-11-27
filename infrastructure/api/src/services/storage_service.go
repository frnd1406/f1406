package services

import (
	"errors"
	"fmt"
	"io"
	"mime"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/sirupsen/logrus"
)

var ErrPathTraversal = errors.New("path escapes base directory")

// StorageEntry represents a file or directory item within the storage root.
type StorageEntry struct {
	Name     string    `json:"name"`
	Size     int64     `json:"size"`
	IsDir    bool      `json:"isDir"`
	ModTime  time.Time `json:"modTime"`
	MimeType string    `json:"mimeType,omitempty"`
	IsImage  bool      `json:"isImage,omitempty"`
}

// TrashEntry represents a soft-deleted file.
type TrashEntry struct {
	ID           string    `json:"id"`           // bucket/relative/path
	Name         string    `json:"name"`         // file name
	OriginalPath string    `json:"originalPath"` // original relative path
	Size         int64     `json:"size"`
	ModTime      time.Time `json:"modTime"`
}

// StorageService provides basic file operations within a confined base directory.
type StorageService struct {
	basePath  string
	trashPath string
	logger    *logrus.Logger
}

// NewStorageService initializes the service and ensures the base path exists.
func NewStorageService(basePath string, logger *logrus.Logger) (*StorageService, error) {
	if basePath == "" {
		return nil, fmt.Errorf("base path is required")
	}

	absBase, err := filepath.Abs(basePath)
	if err != nil {
		return nil, fmt.Errorf("resolve base path: %w", err)
	}

	if err := os.MkdirAll(absBase, 0o755); err != nil {
		return nil, fmt.Errorf("ensure base path: %w", err)
	}

	trash := filepath.Join(absBase, ".trash")
	if err := os.MkdirAll(trash, 0o755); err != nil {
		return nil, fmt.Errorf("ensure trash path: %w", err)
	}

	return &StorageService{
		basePath:  absBase,
		trashPath: trash,
		logger:    logger,
	}, nil
}

func (s *StorageService) sanitizePath(rel string) (string, error) {
	if strings.Contains(rel, "..") {
		return "", ErrPathTraversal
	}
	// Prepend slash so Clean treats it as absolute, then trim to avoid breaking out.
	cleaned := filepath.Clean("/" + rel)
	trimmed := strings.TrimPrefix(cleaned, "/")
	full := filepath.Join(s.basePath, trimmed)

	abs, err := filepath.Abs(full)
	if err != nil {
		return "", err
	}

	if abs != s.basePath && !strings.HasPrefix(abs, s.basePath+string(os.PathSeparator)) {
		return "", ErrPathTraversal
	}

	return abs, nil
}

// List returns the entries for the given relative path.
func (s *StorageService) List(relPath string) ([]StorageEntry, error) {
	target, err := s.sanitizePath(relPath)
	if err != nil {
		return nil, err
	}

	entries, err := os.ReadDir(target)
	if err != nil {
		return nil, err
	}

	var items []StorageEntry
	for _, e := range entries {
		info, err := e.Info()
		if err != nil {
			s.logger.WithError(err).Warn("storage: failed to read entry info")
			continue
		}

		mimeType := ""
		isImage := false
		if !info.IsDir() {
			mimeType = mime.TypeByExtension(filepath.Ext(e.Name()))
			if strings.HasPrefix(mimeType, "image/") {
				isImage = true
			}
		}

		items = append(items, StorageEntry{
			Name:     e.Name(),
			Size:     info.Size(),
			IsDir:    info.IsDir(),
			ModTime:  info.ModTime(),
			MimeType: mimeType,
			IsImage:  isImage,
		})
	}

	return items, nil
}

// Save stores the provided file into the given relative directory.
func (s *StorageService) Save(dir string, file multipart.File, filename string) error {
	if filename == "" {
		return fmt.Errorf("filename is required")
	}

	targetDir, err := s.sanitizePath(dir)
	if err != nil {
		return err
	}

	if err := os.MkdirAll(targetDir, 0o755); err != nil {
		return fmt.Errorf("create target dir: %w", err)
	}

	destPath, err := s.sanitizePath(filepath.Join(dir, filepath.Base(filename)))
	if err != nil {
		return err
	}

	dest, err := os.Create(destPath)
	if err != nil {
		return err
	}
	defer dest.Close()

	if _, err := io.Copy(dest, file); err != nil {
		return fmt.Errorf("write file: %w", err)
	}

	return nil
}

// Open returns a file handle and metadata for download.
func (s *StorageService) Open(relPath string) (*os.File, os.FileInfo, string, error) {
	target, err := s.sanitizePath(relPath)
	if err != nil {
		return nil, nil, "", err
	}

	info, err := os.Stat(target)
	if err != nil {
		return nil, nil, "", err
	}
	if info.IsDir() {
		return nil, nil, "", fmt.Errorf("cannot download a directory")
	}

	f, err := os.Open(target)
	if err != nil {
		return nil, nil, "", err
	}

	ctype := mime.TypeByExtension(filepath.Ext(info.Name()))
	if ctype == "" {
		buf := make([]byte, 512)
		n, _ := f.Read(buf)
		ctype = http.DetectContentType(buf[:n])
		if _, err := f.Seek(0, io.SeekStart); err != nil {
			f.Close()
			return nil, nil, "", err
		}
	}

	return f, info, ctype, nil
}

// Delete removes a file or directory (recursively) within the storage root.
func (s *StorageService) Delete(relPath string) error {
	if relPath == "" || relPath == "/" || relPath == "." {
		return fmt.Errorf("refusing to delete storage root")
	}

	target, err := s.sanitizePath(relPath)
	if err != nil {
		return err
	}

	relClean := strings.TrimPrefix(filepath.Clean(relPath), string(os.PathSeparator))
	bucket := time.Now().UTC().Format("20060102T150405Z")
	destRel := filepath.Join(bucket, relClean)
	destAbs := filepath.Join(s.trashPath, destRel)

	if err := os.MkdirAll(filepath.Dir(destAbs), 0o755); err != nil {
		return fmt.Errorf("create trash dir: %w", err)
	}

	if err := os.Rename(target, destAbs); err != nil {
		return fmt.Errorf("move to trash: %w", err)
	}
	return nil
}

// ListTrash lists all soft-deleted files.
func (s *StorageService) ListTrash() ([]TrashEntry, error) {
	var entries []TrashEntry
	err := filepath.Walk(s.trashPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil
		}
		if info.IsDir() {
			return nil
		}
		rel, err := filepath.Rel(s.trashPath, path)
		if err != nil {
			return nil
		}
		parts := strings.SplitN(rel, string(os.PathSeparator), 2)
		original := ""
		if len(parts) == 2 {
			original = parts[1]
		}
		entries = append(entries, TrashEntry{
			ID:           filepath.ToSlash(rel),
			Name:         info.Name(),
			OriginalPath: filepath.ToSlash(original),
			Size:         info.Size(),
			ModTime:      info.ModTime(),
		})
		return nil
	})
	if err != nil {
		return nil, err
	}
	return entries, nil
}

// RestoreFromTrash moves a file from trash back to its original location.
func (s *StorageService) RestoreFromTrash(id string) error {
	if id == "" {
		return fmt.Errorf("invalid trash id")
	}
	source := filepath.Join(s.trashPath, filepath.FromSlash(id))
	if _, err := os.Stat(source); err != nil {
		return err
	}

	parts := strings.SplitN(id, "/", 2)
	if len(parts) != 2 || parts[1] == "" {
		return fmt.Errorf("missing original path info")
	}
	originalRel := parts[1]
	dest, err := s.sanitizePath(originalRel)
	if err != nil {
		return err
	}

	if err := os.MkdirAll(filepath.Dir(dest), 0o755); err != nil {
		return err
	}
	return os.Rename(source, dest)
}

// DeleteFromTrash removes a trashed file permanently.
func (s *StorageService) DeleteFromTrash(id string) error {
	if id == "" {
		return fmt.Errorf("invalid trash id")
	}
	target := filepath.Join(s.trashPath, filepath.FromSlash(id))
	if !strings.HasPrefix(target, s.trashPath) {
		return ErrPathTraversal
	}
	return os.RemoveAll(target)
}

// Rename renames a file within the same directory.
func (s *StorageService) Rename(oldRel, newName string) error {
	if newName == "" {
		return fmt.Errorf("new name required")
	}
	oldAbs, err := s.sanitizePath(oldRel)
	if err != nil {
		return err
	}
	info, err := os.Stat(oldAbs)
	if err != nil {
		return err
	}
	dir := filepath.Dir(oldAbs)
	newAbs := filepath.Join(dir, filepath.Base(newName))
	if newAbs == oldAbs {
		return nil
	}
	if info.IsDir() {
		return os.Rename(oldAbs, newAbs)
	}
	return os.Rename(oldAbs, newAbs)
}
