package tn.esprit.backend.service.impl;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import tn.esprit.backend.entity.Entreprise;
import tn.esprit.backend.repository.EntrepriseRepository;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class EntrepriseServiceImplTest {

    private EntrepriseRepository repository;
    private EntrepriseServiceImpl service;

    @BeforeEach
    void setUp() {
        repository = mock(EntrepriseRepository.class);
        service = new EntrepriseServiceImpl(repository);
    }

    private Entreprise entreprise(Long id, String nom) {
        Entreprise entreprise = new Entreprise();
        entreprise.setId(id);
        entreprise.setNom(nom);
        entreprise.setAdresse("Tunis");
        return entreprise;
    }

    @Test
    void addEntrepriseReturnsSavedEntity() {
        Entreprise input = entreprise(null, "Example");
        Entreprise saved = entreprise(1L, "Example");
        when(repository.save(input)).thenReturn(saved);

        Entreprise result = service.addEntreprise(input);

        assertSame(saved, result);
        assertEquals(1L, result.getId());
        verify(repository).save(input);
    }

    @Test
    void updateEntrepriseReturnsUpdatedEntity() {
        Entreprise input = entreprise(1L, "Updated");
        Entreprise saved = entreprise(1L, "Updated");
        when(repository.save(input)).thenReturn(saved);

        Entreprise result = service.updateEntreprise(input);

        assertSame(saved, result);
        assertEquals("Updated", result.getNom());
        verify(repository).save(input);
    }

    @Test
    void deleteEntrepriseUsesRequestedId() {
        service.deleteEntreprise(7L);

        verify(repository).deleteById(7L);
        verifyNoMoreInteractions(repository);
    }

    @Test
    void getEntrepriseByIdReturnsExistingEntity() {
        Entreprise expected = entreprise(1L, "Example");
        when(repository.findById(1L)).thenReturn(Optional.of(expected));

        assertSame(expected, service.getEntrepriseById(1L));
        verify(repository).findById(1L);
    }

    @Test
    void getEntrepriseByIdReturnsNullWhenMissing() {
        when(repository.findById(99L)).thenReturn(Optional.empty());

        assertNull(service.getEntrepriseById(99L));
        verify(repository).findById(99L);
    }

    @Test
    void getAllEntreprisesReturnsRepositoryResults() {
        List<Entreprise> expected = List.of(
            entreprise(1L, "First"),
            entreprise(2L, "Second")
        );
        when(repository.findAll()).thenReturn(expected);

        assertEquals(expected, service.getAllEntreprises());
        verify(repository).findAll();
    }

    @Test
    void getAllEntreprisesReturnsEmptyListWhenNoneExist() {
        when(repository.findAll()).thenReturn(List.of());

        assertTrue(service.getAllEntreprises().isEmpty());
        verify(repository).findAll();
    }
}
