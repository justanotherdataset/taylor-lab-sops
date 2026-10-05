\name{point-styles}
\alias{alpha_plot_settings}\alias{alpha_style_data}\alias{alpha_style_layers}
\title{Shared Saved-Result Point Style Helpers}
\usage{
alpha_plot_settings(settings = list())
alpha_style_data(alpha, data, settings = alpha$plot_settings)
alpha_style_layers(z)
}
\arguments{
\item{settings}{Named group, facet, colour/colour_type, shape, fixed_colour/fixed_shape, palette, named colours/shapes, order, trajectories and figure settings.}
\item{alpha}{Result-like list with metadata indexed by sample ID, metadata_types and plot_settings. Shared by alpha and beta.}
\item{data}{Saved point table containing exact sample_id.}
\item{z}{Style object returned by alpha_style_data.}
}
\description{Validates and applies independent metadata colour and categorical shape mappings to saved point data. Missing categories have collision-safe labels, continuous missing colour is grey, and filled symbols use the same selected fill and outline. These helpers do not calculate metrics or fit models.}
\value{Validated settings, styled data with named maps, or ggplot scale/theme layers.}
