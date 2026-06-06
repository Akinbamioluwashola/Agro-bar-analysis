library(shiny)
library(bslib)
library(tidyverse)
library(bsicons)
# --- Data Preparation ---
customers <- read_csv("customers_cleaned.csv", show_col_types = FALSE) |>
  rename(
    Customer_Number = `Customer Number`,
    Customer_Name = `Customer Name`,
    Street_Address = `Street Address`,
    City_County = `City/County`,
    Phone_Number = `Phone Number`,
    Sales_Rep_Number = `Sales Rep Number`,
    Sales_Rep_Name = `Sales Rep Name`
  ) |>
  mutate(
    Sales_Rep_Name = str_to_title(str_trim(Sales_Rep_Name)),
    City_County = coalesce(location, str_to_title(str_trim(City_County)))
  )

# Summaries
rep_stats <- customers |>
  group_by(Sales_Rep_Name) |>
  summarise(
    Customers = n(),
    Locations = n_distinct(City_County),
    .groups = "drop"
  ) |>
  arrange(desc(Customers))

location_stats <- customers |>
  group_by(City_County) |>
  summarise(
    Customers = n(),
    Reps = n_distinct(Sales_Rep_Name),
    .groups = "drop"
  ) |>
  arrange(desc(Customers))

# Cross-tabulation for heatmap
rep_location <- customers |>
  count(Sales_Rep_Name, City_County) |>
  rename(Customers = n)

# Recommendation metrics
total_customers <- nrow(customers)
top5_share <- round(sum(rep_stats$Customers[1:5]) / total_customers * 100, 1)
bottom_reps <- rep_stats |> filter(Customers <= 5)
single_rep_locs <- location_stats |> filter(Reps == 1)
top3_loc_share <- round(sum(location_stats$Customers[1:3]) / total_customers * 100, 1)

# --- UI ---
ui <- page_navbar(
  title = "Agro Bar Magen — Sales Rep Dashboard",
  theme = bs_theme(
    version = 5,
    preset = "flatly",
    primary = "#2c6e49",
    "navbar-bg" = "#2c6e49"
  ),
  fillable = TRUE,

  # ---- Overview Page ----
  nav_panel(
    title = "Overview",
    icon = bs_icon("speedometer2"),
    layout_column_wrap(
      width = 1 / 4,
      fill = FALSE,
      value_box(
        title = "Total Customers",
        value = scales::comma(nrow(customers)),
        showcase = bs_icon("people-fill"),
        theme = "primary"
      ),
      value_box(
        title = "Sales Reps",
        value = n_distinct(customers$Sales_Rep_Name),
        showcase = bs_icon("person-badge"),
        theme = "info"
      ),
      value_box(
        title = "Locations Served",
        value = n_distinct(customers$City_County),
        showcase = bs_icon("geo-alt-fill"),
        theme = "success"
      ),
      value_box(
        title = "Top Rep",
        value = rep_stats$Sales_Rep_Name[1],
        p(paste(rep_stats$Customers[1], "customers")),
        showcase = bs_icon("trophy-fill"),
        theme = "warning"
      )
    ),
    layout_column_wrap(
      width = 1 / 2,
      card(
        full_screen = TRUE,
        card_header("Top 15 Sales Reps by Customer Count"),
        plotOutput("plot_top_reps", height = "400px")
      ),
      card(
        full_screen = TRUE,
        card_header("Top 15 Locations by Customer Count"),
        plotOutput("plot_top_locations", height = "400px")
      )
    )
  ),

  # ---- Sales Rep Page ----
  nav_panel(
    title = "Sales Reps",
    icon = bs_icon("person-lines-fill"),
    layout_sidebar(
      sidebar = sidebar(
        width = 280,
        selectInput(
          "selected_rep", "Select Sales Rep",
          choices = rep_stats$Sales_Rep_Name,
          selected = rep_stats$Sales_Rep_Name[1]
        )
      ),
      layout_column_wrap(
        width = 1 / 3,
        fill = FALSE,
        value_box(
          title = "Customers",
          value = textOutput("rep_customers"),
          showcase = bs_icon("people"),
          theme = "primary"
        ),
        value_box(
          title = "Locations Covered",
          value = textOutput("rep_locations"),
          showcase = bs_icon("pin-map"),
          theme = "success"
        ),
        value_box(
          title = "Rank",
          value = textOutput("rep_rank"),
          showcase = bs_icon("bar-chart-line"),
          theme = "info"
        )
      ),
      layout_column_wrap(
        width = 1 / 2,
        card(
          full_screen = TRUE,
          card_header("Customer Distribution by Location"),
          plotOutput("plot_rep_locations", height = "400px")
        ),
        card(
          full_screen = TRUE,
          card_header("Customer List"),
          tableOutput("table_rep_customers")
        )
      )
    )
  ),

  # ---- Geographic Page ----
  nav_panel(
    title = "Geography",
    icon = bs_icon("globe-americas"),
    layout_sidebar(
      sidebar = sidebar(
        width = 280,
        selectInput(
          "selected_location", "Select Location",
          choices = location_stats$City_County,
          selected = location_stats$City_County[1]
        )
      ),
      layout_column_wrap(
        width = 1 / 3,
        fill = FALSE,
        value_box(
          title = "Customers in Location",
          value = textOutput("loc_customers"),
          showcase = bs_icon("people"),
          theme = "primary"
        ),
        value_box(
          title = "Reps Serving",
          value = textOutput("loc_reps"),
          showcase = bs_icon("person-check"),
          theme = "success"
        ),
        value_box(
          title = "Location Rank",
          value = textOutput("loc_rank"),
          showcase = bs_icon("sort-numeric-down"),
          theme = "info"
        )
      ),
      layout_column_wrap(
        width = 1 / 2,
        card(
          full_screen = TRUE,
          card_header("Sales Reps in This Location"),
          plotOutput("plot_loc_reps", height = "400px")
        ),
        card(
          full_screen = TRUE,
          card_header("Customer List"),
          tableOutput("table_loc_customers")
        )
      )
    )
  ),

  # ---- Heatmap Page ----
  nav_panel(
    title = "Rep × Location",
    icon = bs_icon("grid-3x3"),
    card(
      full_screen = TRUE,
      card_header("Top Reps × Top Locations Heatmap"),
      layout_sidebar(
        sidebar = sidebar(
          width = 250,
          sliderInput("n_reps", "Number of Reps", 5, 20, 10, step = 1),
          sliderInput("n_locs", "Number of Locations", 5, 20, 10, step = 1)
        ),
        plotOutput("plot_heatmap", height = "550px")
      )
    )
  ),

  # ---- Recommendations Page ----
  nav_panel(
    title = "CEO Recommendations",
    icon = bs_icon("lightbulb"),
    layout_column_wrap(
      width = 1 / 2,
      fill = FALSE,

      # Key Findings
      card(
        card_header(
          class = "bg-primary text-white",
          bs_icon("clipboard-data"), " Key Findings"
        ),
        card_body(
          tags$ol(
            tags$li(
              tags$strong("Severe workload imbalance: "),
              paste0("The top 5 reps handle ", top5_share,
                     "% of all customers (", sum(rep_stats$Customers[1:5]),
                     " of ", total_customers,
                     "), while ", nrow(bottom_reps),
                     " reps have 5 or fewer customers each.")
            ),
            tags$li(
              tags$strong("Geographic concentration risk: "),
              paste0("Just 3 locations (Ibadan/Oyo, Ogun, Lagos) account for ",
                     top3_loc_share, "% of the entire customer base.")
            ),
            tags$li(
              tags$strong("Single-rep vulnerability: "),
              paste0(nrow(single_rep_locs),
                     " locations (with ", sum(single_rep_locs$Customers),
                     " customers) are served by only one rep — ",
                     "creating business continuity risk if that rep leaves.")
            ),
            tags$li(
              tags$strong("Territory overlap: "),
              "Ian and Peter share 7 locations, but coverage is heavily lopsided ",
              "(e.g. Ian has 51 customers in Enugu vs. Peter's 3). ",
              "This suggests informal, uncoordinated territory assignment."
            ),
            tags$li(
              tags$strong("Underutilized reps: "),
              paste0(nrow(bottom_reps), " reps have 5 or fewer customers. ",
                     "These may be inactive, new, or misassigned.")
            )
          )
        )
      ),

      # Strategic Recommendations
      card(
        card_header(
          class = "bg-success text-white",
          bs_icon("rocket-takeoff"), " Strategic Recommendations"
        ),
        card_body(
          tags$ol(
            tags$li(
              tags$strong("Rebalance territories: "),
              "Redistribute customers from overloaded reps (Ian, Peter, Stephen Olushola) ",
              "to underutilized reps. Target a maximum of ~120 customers per rep ",
              "to improve service quality."
            ),
            tags$li(
              tags$strong("Formalize territory mapping: "),
              "Assign each location to a primary and backup rep to eliminate ",
              "uncoordinated overlap and ensure coverage continuity."
            ),
            tags$li(
              tags$strong("Audit low-activity reps: "),
              paste0("Review the ", nrow(bottom_reps),
                     " reps with 5 or fewer customers. ",
                     "Determine if they should be reassigned, retrained, or removed.")
            ),
            tags$li(
              tags$strong("Diversify geographic reach: "),
              "Develop growth plans for underserved regions beyond the Ibadan-Ogun-Lagos ",
              "corridor to reduce concentration risk."
            ),
            tags$li(
              tags$strong("Implement rep performance tracking: "),
              "Add revenue and visit-frequency data to this dashboard to move from ",
              "customer-count metrics to value-based territory management."
            )
          )
        )
      )
    ),

    # Supporting visualizations
    layout_column_wrap(
      width = 1 / 2,
      card(
        full_screen = TRUE,
        card_header("Workload Distribution Across Reps"),
        plotOutput("plot_workload", height = "350px")
      ),
      card(
        full_screen = TRUE,
        card_header("Locations at Risk (Single Rep Coverage)"),
        plotOutput("plot_risk_locations", height = "350px")
      )
    )
  )
)

# --- Server ---
server <- function(input, output, session) {
  thematic::thematic_shiny()

  # ---- Overview plots ----
  output$plot_top_reps <- renderPlot({
    rep_stats |>
      slice_head(n = 15) |>
      mutate(Sales_Rep_Name = fct_reorder(Sales_Rep_Name, Customers)) |>
      ggplot(aes(Customers, Sales_Rep_Name)) +
      geom_col(fill = "#2c6e49") +
      geom_text(aes(label = Customers), hjust = -0.2, size = 3.5) +
      labs(x = "Number of Customers", y = NULL) +
      expand_limits(x = max(rep_stats$Customers[1:15]) * 1.1)
  })

  output$plot_top_locations <- renderPlot({
    location_stats |>
      slice_head(n = 15) |>
      mutate(City_County = fct_reorder(City_County, Customers)) |>
      ggplot(aes(Customers, City_County)) +
      geom_col(fill = "#4c956c") +
      geom_text(aes(label = Customers), hjust = -0.2, size = 3.5) +
      labs(x = "Number of Customers", y = NULL) +
      expand_limits(x = max(location_stats$Customers[1:15]) * 1.1)
  })

  # ---- Sales Rep page ----
  rep_data <- reactive({
    customers |> filter(Sales_Rep_Name == input$selected_rep)
  })

  rep_info <- reactive({
    rep_stats |> filter(Sales_Rep_Name == input$selected_rep)
  })

  output$rep_customers <- renderText(rep_info()$Customers)
  output$rep_locations <- renderText(rep_info()$Locations)
  output$rep_rank <- renderText({
    paste("#", which(rep_stats$Sales_Rep_Name == input$selected_rep), "of", nrow(rep_stats))
  })

  output$plot_rep_locations <- renderPlot({
    rep_data() |>
      count(City_County, sort = TRUE) |>
      slice_head(n = 15) |>
      mutate(City_County = fct_reorder(City_County, n)) |>
      ggplot(aes(n, City_County)) +
      geom_col(fill = "#2c6e49") +
      geom_text(aes(label = n), hjust = -0.2, size = 3.5) +
      labs(x = "Customers", y = NULL)
  })

  output$table_rep_customers <- renderTable({
    rep_data() |>
      select(Customer_Name, City_County, Phone_Number) |>
      arrange(City_County)
  })

  # ---- Geography page ----
  loc_data <- reactive({
    customers |> filter(City_County == input$selected_location)
  })

  loc_info <- reactive({
    location_stats |> filter(City_County == input$selected_location)
  })

  output$loc_customers <- renderText(loc_info()$Customers)
  output$loc_reps <- renderText(loc_info()$Reps)
  output$loc_rank <- renderText({
    paste("#", which(location_stats$City_County == input$selected_location), "of", nrow(location_stats))
  })

  output$plot_loc_reps <- renderPlot({
    loc_data() |>
      count(Sales_Rep_Name, sort = TRUE) |>
      mutate(Sales_Rep_Name = fct_reorder(Sales_Rep_Name, n)) |>
      ggplot(aes(n, Sales_Rep_Name)) +
      geom_col(fill = "#4c956c") +
      geom_text(aes(label = n), hjust = -0.2, size = 3.5) +
      labs(x = "Customers", y = NULL)
  })

  output$table_loc_customers <- renderTable({
    loc_data() |>
      select(Customer_Name, Sales_Rep_Name, Phone_Number) |>
      arrange(Sales_Rep_Name)
  })

  # ---- Recommendations page ----
  output$plot_workload <- renderPlot({
    rep_stats |>
      mutate(
        Group = case_when(
          row_number() <= 5 ~ "Top 5",
          Customers <= 5 ~ "5 or fewer",
          TRUE ~ "Middle"
        ),
        Sales_Rep_Name = fct_reorder(Sales_Rep_Name, Customers)
      ) |>
      ggplot(aes(Customers, Sales_Rep_Name, fill = Group)) +
      geom_col() +
      geom_text(aes(label = Customers), hjust = -0.2, size = 3) +
      scale_fill_manual(values = c("Top 5" = "#c0392b", "Middle" = "#2c6e49", "5 or fewer" = "#e67e22")) +
      labs(x = "Number of Customers", y = NULL, fill = NULL) +
      expand_limits(x = max(rep_stats$Customers) * 1.15) +
      theme(legend.position = "top")
  })

  output$plot_risk_locations <- renderPlot({
    single_rep_locs |>
      slice_head(n = 15) |>
      mutate(City_County = fct_reorder(City_County, Customers)) |>
      ggplot(aes(Customers, City_County)) +
      geom_col(fill = "#e67e22") +
      geom_text(aes(label = Customers), hjust = -0.2, size = 3.5) +
      labs(
        x = "Number of Customers", y = NULL,
        subtitle = paste0("Showing top 15 of ", nrow(single_rep_locs), " single-rep locations")
      ) +
      expand_limits(x = max(single_rep_locs$Customers[1:15]) * 1.15)
  })

  # ---- Heatmap page ----
  output$plot_heatmap <- renderPlot({
    top_r <- rep_stats |> slice_head(n = input$n_reps) |> pull(Sales_Rep_Name)
    top_l <- location_stats |> slice_head(n = input$n_locs) |> pull(City_County)

    rep_location |>
      filter(Sales_Rep_Name %in% top_r, City_County %in% top_l) |>
      complete(Sales_Rep_Name = top_r, City_County = top_l, fill = list(Customers = 0)) |>
      mutate(
        Sales_Rep_Name = factor(Sales_Rep_Name, levels = rev(top_r)),
        City_County = factor(City_County, levels = top_l)
      ) |>
      ggplot(aes(City_County, Sales_Rep_Name, fill = Customers)) +
      geom_tile(color = "white", linewidth = 0.5) +
      geom_text(aes(label = ifelse(Customers > 0, Customers, "")), size = 3.5) +
      scale_fill_gradient(low = "#f0f4f0", high = "#2c6e49") +
      labs(x = NULL, y = NULL) +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })
}

shinyApp(ui, server)

