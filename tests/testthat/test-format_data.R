test_that("format_pkncaconc_data generates correct dataset", {
  # Generate sample ADNCA data
  ADNCA <- data.frame(
    STUDYID = rep(1, 10),
    USUBJID = rep(1:2, each = 5),
    PCSPEC = rep("Plasma", 10),
    DRUG = rep("DrugA", 10),
    PARAM = rep("Analyte1", 10),
    DOSNO = rep(1, 10),
    AFRLT = seq(0, 9),
    ARRLT = seq(0, 9),
    AVAL = runif(10),
    ROUTE = c("intravascular")
  )

  # Call format_pkncaconc_data
  df_conc <- format_pkncaconc_data(ADNCA,
                                   group_columns = c("STUDYID", "USUBJID", "PCSPEC",
                                                     "DRUG", "PARAM"),
                                   time_column = "AFRLT",
                                   rrlt_column = "ARRLT")

  # Test if df_conc is a data frame
  expect_s3_class(df_conc, "data.frame")

  # Test if df_conc has the correct columns
  expect_true(all(c("STUDYID", "USUBJID", "PCSPEC", "DRUG", "PARAM",
                    "AFRLT", "AVAL", "conc_groups", "TIME", "TIME_DOSE") %in% colnames(df_conc)))

  # Test if df_conc is correctly grouped and arranged
  expect_equal(df_conc$TIME, df_conc$AFRLT)

  # Test if df_conc can be used with PKNCAconc by testing its output
  expect_no_error(
    PKNCA::PKNCAconc(
      df_conc,
      formula = AVAL ~ TIME | STUDYID + PCSPEC + DRUG + USUBJID / PARAM,
      exclude_half.life = "exclude_half.life",
      time.nominal = "NFRLT"
    )
  )
})

test_that("format_pkncaconc_data generates correct dataset with multiple doses", {
  # Generate sample ADNCA data with at least two doses per subject
  ADNCA <- data.frame(
    STUDYID = rep(1, 20),
    USUBJID = rep(1:2, each = 10),
    PCSPEC = rep("Plasma", 20),
    DRUG = rep("DrugA", 20),
    PARAM = rep("Analyte1", 20),
    AFRLT = rep(seq(0, 9), 2),
    ARRLT = c(rep(seq(0, 4), 2), rep(seq(0, 4), 2)),
    ROUTE = "intravascular",
    DOSNO = rep(rep(1:2, each = 5), 2),
    AVAL = runif(20)
  )

  # Call format_pkncaconc_data
  df_conc <- format_pkncaconc_data(ADNCA,
                                   group_columns = c("STUDYID", "USUBJID", "PCSPEC",
                                                     "DRUG", "PARAM"),
                                   time_column = "AFRLT",
                                   rrlt_column = "ARRLT")

  # Test if df_conc is a data frame
  expect_s3_class(df_conc, "data.frame")

  # Test if df_conc has the correct columns
  expect_true(all(c("STUDYID", "USUBJID", "PCSPEC",
                    "DRUG", "PARAM", "DOSNO",
                    "AFRLT", "AVAL", "conc_groups",
                    "TIME", "TIME_DOSE") %in% colnames(df_conc)))

  # Test if df_conc is correctly grouped and arranged
  expect_equal(df_conc$TIME, df_conc$AFRLT)
  expect_equal(
    df_conc %>%
      dplyr::arrange(USUBJID, DOSNO) %>%
      dplyr::pull(TIME_DOSE),
    rep(c(rep(0, 5), rep(5, 5)), 2)
  )

  # Test if df_conc can be used with PKNCAconc by testing its output
  expect_no_error(
    PKNCA::PKNCAconc(
      df_conc,
      formula = AVAL ~ TIME | STUDYID + PCSPEC + DRUG + USUBJID / PARAM,
      exclude_half.life = "exclude_half.life",
      time.nominal = "NFRLT"
    )
  )
})

test_that("format_pkncaconc_data handles empty input", {
  ADNCA <- data.frame()
  expect_error(format_pkncaconc_data(ADNCA,
                                     group_columns = c("STUDYID", "USUBJID", "PCSPEC",
                                                       "DRUG", "PARAM"),
                                     time_column = "AFRLT"),
               regexp = "Input dataframe is empty. Please provide a valid ADNCA dataframe.")
})

test_that("format_pkncaconc_data handles missing columns", {
  ADNCA <- data.frame(
    STUDYID = rep(1, 10),
    USUBJID = rep(1:2, each = 5),
    PCSPEC = rep("Plasma", 10),
    DRUG = rep("DrugA", 10),
    DOSNO = rep(1, 10),
    AFRLT = seq(0, 9),
    ARRLT = seq(0, 9),
    AVAL = runif(10),
    ROUTE = c("intravascular")
  )
  expect_error(
    format_pkncaconc_data(
      ADNCA,
      group_columns = c("STUDYID", "USUBJID", "PCSPEC", "DRUG", "PARAM"),
      time_column = "AFRLT"
    ),
    regexp = "Missing required columns: PARAM"
  )
})

test_that("format_pkncaconc_data handles multiple analytes", {
  ADNCA <- data.frame(
    STUDYID = rep(1, 20),
    USUBJID = rep(1, each = 10),
    PCSPEC = rep("Plasma", 20),
    DRUG = rep("DrugA", 20),
    DOSNO = rep(1, 20),
    PARAM = rep(c("Analyte1", "Analyte2"), each = 10),
    AFRLT = rep(seq(0, 9), 2),
    ARRLT = rep(seq(0, 9), 2),
    AVAL = runif(20),
    ROUTE = c("intravascular")
  )
  df_conc <- format_pkncaconc_data(ADNCA,
                                   group_columns = c("STUDYID", "USUBJID", "PCSPEC",
                                                     "DRUG", "PARAM"),
                                   time_column = "AFRLT")
  expect_equal(nrow(df_conc), 20)
  expect_equal(length(unique(df_conc$PARAM)), 2)
})

test_that("format_pkncadose_data generates with no errors", {

  ADNCA <- data.frame(
    STUDYID = rep(1, 20),
    USUBJID = rep(1:2, each = 10),
    PCSPEC = rep("Plasma", 20),
    DRUG = rep("DrugA", 20),
    PARAM = rep("Analyte1", 20),
    AFRLT = rep(seq(0, 9), 2),
    ARRLT = rep(seq(0, 4), 4),
    NFRLT = rep(seq(0, 9), 2),
    DOSNO = rep(1, 20),
    DOSEA = rep(c(5, 10), each = 10),
    ROUTE = rep(c("intravascular", "extravascular"), each = 10),
    ADOSEDUR = rep(c(0, 0), each = 10),
    AVAL = runif(20)
  )

  # Call format_pkncaconc_data
  df_conc <- format_pkncaconc_data(ADNCA,
                                   group_columns = c("STUDYID", "USUBJID", "PCSPEC",
                                                     "DRUG", "PARAM"),
                                   time_column = "AFRLT")

  # Call format_pkncadose_data
  df_dose <- format_pkncadose_data(df_conc,
                                   group_columns = c("STUDYID", "USUBJID", "PCSPEC",
                                                     "DRUG", "PARAM"),
                                   time_column = "AFRLT")

  # Test if df_dose is a data frame
  expect_s3_class(df_dose, "data.frame")

  # Test if df_dose has the correct columns
  expect_true(all(c("STUDYID", "USUBJID", "PCSPEC",
                    "DRUG", "PARAM", "AFRLT",
                    "ARRLT", "AVAL", "conc_groups",
                    "TIME", "TIME_DOSE", "DOSNOA", "ROUTE") %in% colnames(df_dose)))

  # Test if df_dose can be used with PKNCAdose by testing its output
  expect_no_error(
    PKNCA::PKNCAdose(
      data = df_dose,
      formula = DOSEA ~ TIME_DOSE | STUDYID + PCSPEC + DRUG + USUBJID,
      route = "ROUTE",
      time.nominal = "NFRLT",
      duration = "ADOSEDUR"
    )
  )

  # Test if each subject has at least two doses
  dose_counts <- df_dose %>% group_by(USUBJID) %>% summarise(n = n())
  expect_true(all(dose_counts$n >= 2))
})

test_that("format_pkncadose_data handles empty input", {
  df_conc <- data.frame()
  expect_error(format_pkncadose_data(df_conc,
                                     group_columns = c("STUDYID", "USUBJID", "PCSPEC",
                                                       "DRUG"),
                                     time_column = "AFRLT"),
               regexp = "Input dataframe is empty. Please provide a valid concentration dataframe.")
})

test_that("format_pkncadata_intervals handles incorrect input type", {
  ADNCA <- data.frame(
    STUDYID = rep(1, 20),
    USUBJID = rep(1:2, each = 10),
    PCSPEC = rep("Plasma", 20),
    DRUG = rep("DrugA", 20),
    PARAM = rep("Analyte1", 20),
    AFRLT = rep(seq(0, 9), 2),
    ARRLT = rep(seq(0, 4), 4),
    NFRLT = rep(seq(0, 9), 2),
    ROUTE = "extravascular",
    DOSNO = rep(1, 20),
    DOSEA = 10,
    ADOSEDUR = 0,
    AVAL = runif(20)
  )

  # Call format_pkncaconc_data
  df_conc <- format_pkncaconc_data(ADNCA,
                                   group_columns = c("STUDYID", "USUBJID", "PCSPEC",
                                                     "DRUG", "PARAM"),
                                   time_column = "AFRLT")

  # Generate PKNCAconc and PKNCAdose objects
  pknca_conc <- PKNCA::PKNCAconc(
    df_conc,
    formula = AVAL ~ TIME | STUDYID + PCSPEC + DRUG + USUBJID / PARAM,
    exclude_half.life = "exclude_half.life",
    time.nominal = "NFRLT"
  )
  expect_error(format_pkncadata_intervals(pknca_conc = df_conc, data.frame()),
               regexp = "Input pknca_conc must be a PKNCAconc object from the PKNCA package.")

  expect_error(format_pkncadata_intervals(pknca_conc = pknca_conc, data.frame()),
               regexp = "Input pknca_dose must be a PKNCAdose object from the PKNCA package.")
})

test_that("format_pkncadose_data handles negative time values", {
  df_adnca <- data.frame(
    STUDYID = rep(1, 10),
    USUBJID = rep(1:2, each = 5),
    PCSPEC = rep("Plasma", 10),
    DRUG = rep("DrugA", 10),
    PARAM = rep("Analyte1", 10),
    AFRLT = c(-1, 0, 1, 2, 3, -1, 0, 1, 2, 3),
    ARRLT = c(-1, 0, 1, 2, 3, -1, 0, 1, 2, 3),
    ROUTE = rep(c("intravascular", "extravascular"), each = 5),
    DOSEA = 10,
    AVAL = runif(10)
  )

  df_conc <- format_pkncaconc_data(df_adnca,
                                   group_columns = c("STUDYID", "USUBJID", "PCSPEC",
                                                     "DRUG", "PARAM"),
                                   time_column = "AFRLT")
  df_dose <- format_pkncadose_data(df_conc,
                                   group_columns = c("STUDYID", "USUBJID", "PCSPEC",
                                                     "DRUG", "PARAM"),
                                   time_column = "AFRLT")
  expect_true(all(df_dose$TIME_DOSE >= 0))
})

test_that("format_pkncadose_data handles multiple analytes", {
  df_adnca <- data.frame(
    STUDYID = rep(1, 20),
    USUBJID = rep(1:2, each = 10),
    PCSPEC = rep("Plasma", 20),
    DRUG = rep("DrugA", 20),
    PARAM = rep(rep(c("Analyte1", "Analyte2"), 2), each = 5),
    AFRLT = rep(seq(0, 9), 2),
    ARRLT = c(rep(seq(0, 4), 2), rep(seq(5, 9), 2)),
    ROUTE = rep(c("intravascular", "extravascular"), each = 10),
    DOSEA = 10,
    AVAL = runif(20)
  )
  df_conc <- format_pkncaconc_data(df_adnca,
                                   group_columns = c("STUDYID", "USUBJID", "PCSPEC",
                                                     "DRUG", "PARAM"),
                                   time_column = "AFRLT")
  df_dose <- format_pkncadose_data(df_conc,
                                   group_columns = c("STUDYID", "USUBJID", "PCSPEC",
                                                     "DRUG", "PARAM"),
                                   time_column = "AFRLT")
  expect_equal(nrow(df_dose), 4)
  expect_equal(length(unique(df_dose$PARAM)), 2)
})

test_that("format_pkncadata_intervals generates correct dataset", {
  # Generate sample ADNCA data with at least two doses per subject
  ADNCA <- data.frame(
    STUDYID = rep(1, 20),
    USUBJID = rep(1:2, each = 10),
    PCSPEC = rep("Plasma", 20),
    DRUG = rep("DrugA", 20),
    PARAM = rep("Analyte1", 20),
    AFRLT = rep(seq(0, 9), 2),
    ARRLT = rep(seq(0, 4), 4),
    NFRLT = rep(seq(0, 9), 2),
    DOSNO = rep(1, 20),
    ROUTE = "extravascular",
    DOSEA = 10,
    ADOSEDUR = 0,
    AVAL = runif(20)
  )

  # Call format_pkncaconc_data
  df_conc <- format_pkncaconc_data(ADNCA,
                                   group_columns = c("STUDYID", "USUBJID", "PCSPEC",
                                                     "DRUG", "PARAM"),
                                   time_column = "AFRLT")

  # Call format_pkncadose_data
  df_dose <- format_pkncadose_data(df_conc,
                                   group_columns = c("STUDYID", "USUBJID", "PCSPEC",
                                                     "DRUG", "PARAM"),
                                   time_column = "AFRLT")

  # Generate PKNCAconc and PKNCAdose objects
  pknca_conc <- PKNCA::PKNCAconc(
    df_conc,
    formula = AVAL ~ TIME | STUDYID + PCSPEC + DRUG + USUBJID / PARAM,
    exclude_half.life = "exclude_half.life",
    time.nominal = "NFRLT"
  )

  pknca_dose <- PKNCA::PKNCAdose(
    data = df_dose,
    formula = DOSEA ~ TIME_DOSE | STUDYID + PCSPEC + DRUG + USUBJID,
    route = "ROUTE",
    time.nominal = "NFRLT",
    duration = "ADOSEDUR"
  )

  # Define the other arguments for the dose intervals
  params <- c("cmax", "tmax", "half.life", "cl.obs")

  # Call format_pkncadata_intervals
  myintervals <- format_pkncadata_intervals(pknca_conc,
                                            pknca_dose,
                                            params = params,
                                            start_from_last_dose = TRUE)

  # Test if myintervals is a data frame
  expect_s3_class(myintervals, "data.frame")

  # Test if myintervals has the correct columns
  expect_true(all(c("start", "end", "STUDYID",
                    "USUBJID", "DOSNOA", "type_interval") %in% colnames(myintervals)))

  # Test if interval types are classified as "main"
  expect_true(all(myintervals$type_interval == "main"))

  # Test if myintervals can be used with PKNCAdata by testing its output
  expect_no_error(
    PKNCA::PKNCAdata(
      data.conc = pknca_conc,
      data.dose = pknca_dose,
      intervals = myintervals,
      units = PKNCA::pknca_units_table(
        concu = pknca_conc$data$PCSTRESU[1],
        doseu = pknca_conc$data$DOSEU[1],
        amountu = pknca_conc$data$PCSTRESU[1],
        timeu = pknca_conc$data$RRLTU[1]
      )
    )
  )
})

test_that("format_pkncaconc_data generates a correct temporary route column", {
  ADNCA <- data.frame(
    STUDYID = rep(1, 20),
    USUBJID = rep(1:2, each = 10),
    PCSPEC = rep("Plasma", 20),
    DRUG = rep("DrugA", 20),
    PARAM = rep("Analyte1", 10),
    ROUTE = rep(c("INTRAVASCULAR",
                  "INTRAVENOUS",
                  "INTRAVENOUS BOLUS",
                  "INTRAVENOUS DRIP",
                  "EXTRAVASCULAR"), 2),
    DOSEA = 10,
    DOSNO = rep(1, 20),
    AVAL = runif(20),
    AFRLT = rep(seq(0, 9), 2),
    ARRLT = rep(seq(0, 9), 2)
  )

  df_conc <- format_pkncaconc_data(ADNCA,
                                   group_columns = c("STUDYID", "USUBJID", "PCSPEC",
                                                     "DRUG", "PARAM"),
                                   time_column = "AFRLT")

  translated_routes <- df_conc$std_route

  purrr::walk(1:4, \(i) expect_equal(translated_routes[i], "intravascular"))
  expect_equal(translated_routes[5], "extravascular")
})

test_that("format_pkncadata_intervals handles multiple analytes with metabolites", {

  # Create mock data with multiple analytes and metabolites
  ADNCA <- data.frame(
    STUDYID = rep(1, 20),
    USUBJID = rep(1, 20),
    PCSPEC = rep("Plasma", 20),
    DRUG = rep("DrugA", 20),
    DOSEA = 10,
    DOSNO = rep(1, 20),
    PARAM = rep(c("Analyte1", "Metabolite1"), each = 10),
    AFRLT = rep(seq(0, 9), 2),
    ARRLT = rep(seq(0, 9), 2),
    AVAL = c(rep(seq(0, 8, 2), 2),
             rep(seq(0, 4), 2)),
    ROUTE = rep("extravascular", 20)
  )

  # Call format_pkncaconc_data
  df_conc <- format_pkncaconc_data(ADNCA,
                                   group_columns = c("STUDYID", "USUBJID", "PCSPEC",
                                                     "DRUG", "PARAM"),
                                   time_column = "AFRLT")

  # Call format_pkncadose_data
  df_dose <- format_pkncadose_data(df_conc,
                                   group_columns = c("STUDYID", "USUBJID", "PCSPEC",
                                                     "DRUG"),
                                   time_column = "AFRLT")

  # Generate PKNCAconc and PKNCAdose objects
  pknca_conc <- PKNCA::PKNCAconc(
    df_conc,
    formula = AVAL ~ TIME | STUDYID + PCSPEC + DRUG + USUBJID / PARAM,
    exclude_half.life = "exclude_half.life",
    time.nominal = "NFRLT"
  )

  pknca_dose <- PKNCA::PKNCAdose(
    data = df_dose,
    formula = DOSEA ~ TIME_DOSE | STUDYID + PCSPEC + DRUG + USUBJID
  )

  # Define the parameters for the dose intervals
  params <- c("cmax", "tmax", "half.life", "cl.obs")

  # Test function
  result <- format_pkncadata_intervals(pknca_conc, pknca_dose, params = params)

  expect_equal(result$start[1], 0)
  expect_equal(result$end[1], Inf)
  expect_equal(result$PARAM, c("Analyte1", "Metabolite1"))
  expect_equal(result$cmax[1], TRUE)
  expect_equal(result$tmax[1], TRUE)
  expect_equal(result$half.life[1], TRUE)
  expect_equal(result$cl.obs[1], TRUE)


  # Test if result can be used with PKNCAdata by testing its output
  expect_no_error(
    PKNCA::PKNCAdata(
      data.conc = pknca_conc,
      data.dose = pknca_dose,
      intervals = result,
      units = PKNCA::pknca_units_table(
        concu = "ng/mL",
        doseu = "mg",
        amountu = "ng",
        timeu = "h"
      )
    )
  )
})
