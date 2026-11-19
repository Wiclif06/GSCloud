package br.com.fiap.citizentech.cloud;

import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class CloudVersionControllerTests {
    @Test
    void exposesTheDeploymentCommitAndSourceMessage() throws Exception {
        MockMvc mvc = MockMvcBuilders.standaloneSetup(new CloudVersionController("commit-da-ci")).build();
        mvc.perform(get("/version"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.application").value("AgroConecta"))
                .andExpect(jsonPath("$.commit").value("commit-da-ci"))
                .andExpect(jsonPath("$.message").isNotEmpty());
    }
}
